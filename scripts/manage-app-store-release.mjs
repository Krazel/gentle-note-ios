import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const mode = process.argv[2] ?? "audit";
const confirmations = new Set(process.argv.slice(3));
const metadata = JSON.parse(fs.readFileSync("app-store/metadata.json", "utf8"));
const appId = metadata.appId;
const publicVersion = metadata.publicReleaseVersion;
const keyId = requiredEnvironment("ASC_KEY_ID");
const issuerId = requiredEnvironment("ASC_ISSUER_ID");
const privateKey = fs.readFileSync(requiredEnvironment("ASC_PRIVATE_KEY_PATH"), "utf8");
const token = createToken({ keyId, issuerId, privateKey });

if (!new Set(["audit", "prepare-metadata", "prepare-review", "upload-screenshots"]).has(mode)) {
  fail("Use audit, prepare-metadata, prepare-review, or upload-screenshots.");
}
if (mode === "prepare-metadata" && !confirmations.has("--confirm-metadata-write")) {
  fail("Metadata writes require --confirm-metadata-write.");
}
if (mode === "upload-screenshots" && !confirmations.has("--confirm-screenshot-upload")) {
  fail("Screenshot uploads require --confirm-screenshot-upload.");
}
if (mode === "prepare-review" && !confirmations.has("--confirm-review-write")) {
  fail("App Review writes require --confirm-review-write.");
}

const app = (await request("GET", `/v1/apps/${appId}`)).data;
if (app.attributes?.bundleId !== metadata.bundleId) fail("App bundle identifier does not match metadata.json.");
const versions = (await request("GET", `/v1/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=50`)).data ?? [];
const releaseVersion = versions.find((item) => item.attributes?.versionString === publicVersion);
const appInfos = (await request("GET", `/v1/apps/${appId}/appInfos?limit=20`)).data ?? [];
const appInfo = appInfos[0];

if (mode === "audit") {
  const buildQuery = new URLSearchParams({ "filter[app]": appId, sort: "-uploadedDate", limit: "10" });
  const builds = (await request("GET", `/v1/builds?${buildQuery}`)).data ?? [];
  const output = {
    status: "AUDITED",
    appId,
    bundleId: app.attributes?.bundleId,
    appStoreVersion: releaseVersion ? {
      id: releaseVersion.id,
      versionString: releaseVersion.attributes?.versionString,
      state: releaseVersion.attributes?.appStoreState ?? releaseVersion.attributes?.appVersionState ?? null
    } : null,
    appInfoId: appInfo?.id ?? null,
    latestBuilds: builds.slice(0, 5).map((build) => ({
      id: build.id,
      buildNumber: build.attributes?.version,
      processingState: build.attributes?.processingState,
      uploadedDate: build.attributes?.uploadedDate
    }))
  };
  console.log(JSON.stringify(output));
  process.exit(0);
}

if (!releaseVersion) {
  fail(`App Store version ${publicVersion} does not exist. Create it only after the owner approves 1.0 and supplies the final copyright.`);
}
if (!appInfo) fail("No editable appInfo resource was found.");

const versionLocalizations = (await request("GET", `/v1/appStoreVersions/${releaseVersion.id}/appStoreVersionLocalizations?limit=50`)).data ?? [];
const infoLocalizations = (await request("GET", `/v1/appInfos/${appInfo.id}/appInfoLocalizations?limit=50`)).data ?? [];

if (mode === "prepare-metadata") {
  for (const [locale, record] of Object.entries(metadata.localizations)) {
    const existingInfo = ((await request("GET", `/v1/appInfos/${appInfo.id}/appInfoLocalizations?filter[locale]=${encodeURIComponent(locale)}&limit=10`)).data ?? [])[0];
    const infoAttributes = {
      name: record.name,
      subtitle: record.subtitle,
      privacyPolicyUrl: record.privacyPolicyUrl
    };
    if (existingInfo) {
      await request("PATCH", `/v1/appInfoLocalizations/${existingInfo.id}`, {
        data: { type: "appInfoLocalizations", id: existingInfo.id, attributes: infoAttributes }
      });
    } else {
      await request("POST", "/v1/appInfoLocalizations", {
        data: {
          type: "appInfoLocalizations",
          attributes: { locale, ...infoAttributes },
          relationships: { appInfo: { data: { type: "appInfos", id: appInfo.id } } }
        }
      });
    }

    const existingVersion = ((await request("GET", `/v1/appStoreVersions/${releaseVersion.id}/appStoreVersionLocalizations?filter[locale]=${encodeURIComponent(locale)}&limit=10`)).data ?? [])[0];
    const versionAttributes = {
      description: record.description,
      keywords: record.keywords,
      supportUrl: record.supportUrl
    };
    if (existingVersion) {
      await request("PATCH", `/v1/appStoreVersionLocalizations/${existingVersion.id}`, {
        data: { type: "appStoreVersionLocalizations", id: existingVersion.id, attributes: versionAttributes }
      });
    } else {
      await request("POST", "/v1/appStoreVersionLocalizations", {
        data: {
          type: "appStoreVersionLocalizations",
          attributes: { locale, ...versionAttributes },
          relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: releaseVersion.id } } }
        }
      });
    }
  }
  console.log(JSON.stringify({ status: "METADATA_PREPARED", appId, versionId: releaseVersion.id, versionString: publicVersion, locales: Object.keys(metadata.localizations) }));
  process.exit(0);
}

if (mode === "prepare-review") {
  const review = metadata.review ?? {};
  if (!review.copyright || !review.contactSourceAppId || !review.contactSourceVersion) {
    fail("metadata.json must define review copyright and the existing contact source app/version.");
  }
  const sourceVersions = (await request(
    "GET",
    `/v1/apps/${review.contactSourceAppId}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${encodeURIComponent(review.contactSourceVersion)}&limit=10`
  )).data ?? [];
  const sourceVersion = sourceVersions[0];
  if (!sourceVersion) fail("The approved App Review contact source version was not found.");
  const sourceDetail = (await request("GET", `/v1/appStoreVersions/${sourceVersion.id}/appStoreReviewDetail`)).data;
  const contact = Object.fromEntries(
    ["contactFirstName", "contactLastName", "contactPhone", "contactEmail"]
      .map((key) => [key, sourceDetail?.attributes?.[key]?.trim() ?? ""])
  );
  if (Object.values(contact).some((value) => !value)) {
    fail("The approved App Review contact source is incomplete.");
  }
  if (!contact.contactPhone.startsWith("+")) {
    fail("The approved App Review contact phone is not in international format.");
  }
  const targetDetail = (await request("GET", `/v1/appStoreVersions/${releaseVersion.id}/appStoreReviewDetail`)).data;
  if (!targetDetail?.id) fail("Gentle Note App Review detail is missing.");
  const notes = fs.readFileSync("app-store/review-notes.txt", "utf8").trim();
  await request("PATCH", `/v1/appStoreReviewDetails/${targetDetail.id}`, {
    data: {
      type: "appStoreReviewDetails",
      id: targetDetail.id,
      attributes: { ...contact, notes }
    }
  });
  const verifiedDetail = (await request("GET", `/v1/appStoreReviewDetails/${targetDetail.id}`)).data;
  const verifiedAttributes = verifiedDetail?.attributes ?? {};
  const contactVerified = Object.entries(contact)
    .every(([key, value]) => verifiedAttributes[key]?.trim() === value);
  const notesVerified = verifiedAttributes.notes?.trim() === notes;
  if (!contactVerified || !notesVerified) {
    fail("App Store Connect did not preserve the authorized App Review details exactly.");
  }
  await request("PATCH", `/v1/appStoreVersions/${releaseVersion.id}`, {
    data: {
      type: "appStoreVersions",
      id: releaseVersion.id,
      attributes: { copyright: review.copyright }
    }
  });
  console.log(JSON.stringify({
    status: "APP_REVIEW_DETAILS_PREPARED",
    appId,
    versionId: releaseVersion.id,
    versionString: publicVersion,
    contact: "COPIED_WITHIN_APP_STORE_CONNECT",
    contactVerified,
    notesLength: notes.length,
    notesVerified,
    copyright: review.copyright
  }));
  process.exit(0);
}

const screenshotRoot = requiredEnvironment("SCREENSHOT_DIRECTORY");
for (const [locale] of Object.entries(metadata.localizations)) {
  const localization = versionLocalizations.find((item) => item.attributes?.locale === locale);
  if (!localization) fail(`Missing App Store version localization for ${locale}; prepare metadata first.`);
  const directory = path.join(screenshotRoot, locale);
  const files = fs.readdirSync(directory).filter((name) => /\.(jpg|jpeg|png)$/i.test(name)).sort();
  if (files.length < 1 || files.length > 10) fail(`Expected 1-10 screenshots for ${locale}; found ${files.length}.`);

  let sets = (await request("GET", `/v1/appStoreVersionLocalizations/${localization.id}/appScreenshotSets?filter[screenshotDisplayType]=APP_IPHONE_65&limit=10`)).data ?? [];
  let set = sets[0];
  if (!set) {
    set = (await request("POST", "/v1/appScreenshotSets", {
      data: {
        type: "appScreenshotSets",
        attributes: { screenshotDisplayType: "APP_IPHONE_65" },
        relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: localization.id } } }
      }
    })).data;
  }
  const existing = (await request("GET", `/v1/appScreenshotSets/${set.id}/appScreenshots?limit=20`)).data ?? [];
  if (existing.length > 0) fail(`Screenshot set for ${locale} is not empty; refusing to replace existing assets automatically.`);

  const uploadedIds = [];
  for (const filename of files) {
    const filePath = path.join(directory, filename);
    const data = fs.readFileSync(filePath);
    const reservation = (await request("POST", "/v1/appScreenshots", {
      data: {
        type: "appScreenshots",
        attributes: { fileName: filename, fileSize: data.length },
        relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set.id } } }
      }
    })).data;
    for (const operation of reservation.attributes?.uploadOperations ?? []) {
      const headers = Object.fromEntries((operation.requestHeaders ?? []).map((header) => [header.name, header.value]));
      const slice = data.subarray(operation.offset, operation.offset + operation.length);
      const response = await fetch(operation.url, { method: operation.method, headers, body: slice });
      if (!response.ok) fail(`Screenshot part upload failed for ${filename}: ${response.status}`);
    }
    const checksum = crypto.createHash("md5").update(data).digest("hex");
    await request("PATCH", `/v1/appScreenshots/${reservation.id}`, {
      data: { type: "appScreenshots", id: reservation.id, attributes: { uploaded: true, sourceFileChecksum: checksum } }
    });
    await waitForScreenshot(reservation.id, filename);
    uploadedIds.push(reservation.id);
  }
  await request("PATCH", `/v1/appScreenshotSets/${set.id}/relationships/appScreenshots`, {
    data: uploadedIds.map((id) => ({ type: "appScreenshots", id }))
  });
}
console.log(JSON.stringify({ status: "SCREENSHOTS_UPLOADED", appId, versionId: releaseVersion.id, versionString: publicVersion, locales: Object.keys(metadata.localizations) }));

async function waitForScreenshot(id, filename) {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    const screenshot = (await request("GET", `/v1/appScreenshots/${id}`)).data;
    const state = screenshot.attributes?.assetDeliveryState?.state;
    if (state === "COMPLETE") return;
    if (state === "FAILED") fail(`Apple failed to process ${filename}: ${JSON.stringify(screenshot.attributes?.assetDeliveryState?.errors ?? [])}`);
    await new Promise((resolve) => setTimeout(resolve, 4_000));
  }
  fail(`Timed out waiting for Apple to process ${filename}.`);
}

async function request(method, endpoint, body) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${endpoint}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, ...(body ? { "Content-Type": "application/json" } : {}) },
    body: body ? JSON.stringify(body) : undefined
  });
  const text = await response.text();
  const json = text ? JSON.parse(text) : {};
  if (!response.ok) fail(`App Store Connect API failed ${method} ${endpoint}: ${response.status} ${text}`);
  return json;
}

function createToken({ keyId: kid, issuerId: iss, privateKey: key }) {
  const now = Math.floor(Date.now() / 1000);
  const input = `${base64url(JSON.stringify({ alg: "ES256", kid, typ: "JWT" }))}.${base64url(JSON.stringify({ iss, aud: "appstoreconnect-v1", exp: now + 19 * 60, iat: now }))}`;
  const signer = crypto.createSign("SHA256");
  signer.update(input); signer.end();
  return `${input}.${base64url(signer.sign({ key, dsaEncoding: "ieee-p1363" }))}`;
}
function base64url(value) { return Buffer.from(value).toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_"); }
function requiredEnvironment(name) { const value = process.env[name]?.trim(); if (!value) fail(`Missing ${name}.`); return value; }
function fail(message) { console.error(message); process.exit(1); }
