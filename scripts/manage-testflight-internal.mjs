import crypto from "node:crypto";
import fs from "node:fs";

const appId = "6805943178";
const bundleId = "com.krazel.gentlenote.B2X6D3A9J9";
const marketingVersion = "0.7.1";
const buildNumber = "1";
const groupName = "Testers";
const mode = process.argv[2] ?? "status";

if (!new Set(["status", "assign"]).has(mode)) {
  fail("Usage: node scripts/manage-testflight-internal.mjs [status|assign] [confirmation]");
}
if (mode === "assign" && process.argv[3] !== "--confirm-private-internal-group") {
  fail("Assignment requires --confirm-private-internal-group.");
}

const keyId = requiredEnvironment("ASC_KEY_ID");
const issuerId = requiredEnvironment("ASC_ISSUER_ID");
const privateKeyPath = requiredEnvironment("ASC_PRIVATE_KEY_PATH");
const token = createToken({
  keyId,
  issuerId,
  privateKey: fs.readFileSync(privateKeyPath, "utf8")
});

const appResponse = await request(token, "GET", `/v1/apps/${appId}`);
if (appResponse.data?.attributes?.bundleId !== bundleId) {
  fail(`App ${appId} is not the expected bundle ${bundleId}.`);
}

const buildQuery = new URLSearchParams({
  "filter[app]": appId,
  "filter[version]": buildNumber,
  "sort": "-uploadedDate",
  "limit": "10",
  "fields[builds]": "version,uploadedDate,expirationDate,expired,processingState,buildAudienceType,usesNonExemptEncryption"
});
const candidateResponse = await request(token, "GET", `/v1/builds?${buildQuery}`);
const latestCandidate = candidateResponse.data?.[0];
if (!latestCandidate) {
  console.log(JSON.stringify({ status: "BUILD_NOT_VISIBLE", appId, bundleId, marketingVersion, buildNumber }));
  process.exit(0);
}
const versionResponse = await request(token, "GET", `/v1/builds/${latestCandidate.id}/preReleaseVersion`);
const latestMarketingVersion = versionResponse.data?.attributes?.version;
if (latestMarketingVersion !== marketingVersion) {
  console.log(JSON.stringify({
    status: "BUILD_NOT_VISIBLE",
    appId,
    bundleId,
    marketingVersion,
    buildNumber,
    latestMatchingBuildNumberBelongsToVersion: latestMarketingVersion ?? null
  }));
  process.exit(0);
}

const build = latestCandidate;
const betaDetailResponse = await request(token, "GET", `/v1/builds/${build.id}/buildBetaDetail`);
const internalBuildState = betaDetailResponse.data?.attributes?.internalBuildState;
const externalBuildState = betaDetailResponse.data?.attributes?.externalBuildState;
const processingState = build.attributes?.processingState;
const audience = build.attributes?.buildAudienceType;
const isInternalTestingAvailable = new Set(["READY_FOR_BETA_TESTING", "IN_BETA_TESTING"]).has(internalBuildState);

if (processingState !== "VALID") {
  console.log(JSON.stringify({
    status: "BUILD_NOT_READY",
    appId,
    bundleId,
    buildId: build.id,
    marketingVersion,
    buildNumber: build.attributes?.version,
    processingState,
    internalBuildState,
    externalBuildState,
    buildAudienceType: audience,
    uploadedDate: build.attributes?.uploadedDate
  }));
  process.exit(0);
}
if (!new Set(["INTERNAL_ONLY", "APP_STORE_ELIGIBLE"]).has(audience)) {
  fail(`Build ${build.id} has unsupported audience ${audience ?? "missing"}.`);
}

const groupsResponse = await request(token, "GET", `/v1/apps/${appId}/betaGroups?limit=200`);
const matchingGroups = (groupsResponse.data ?? []).filter((group) => group.attributes?.name === groupName);
if (matchingGroups.length !== 1) {
  fail(`Expected exactly one beta group named ${groupName}; found ${matchingGroups.length}.`);
}
const group = matchingGroups[0];
if (group.attributes?.isInternalGroup !== true || group.attributes?.publicLinkEnabled === true) {
  fail(`Group ${groupName} is not a private internal group.`);
}

const linkedResponse = await request(token, "GET", `/v1/betaGroups/${group.id}/relationships/builds?limit=200`);
const alreadyLinked = (linkedResponse.data ?? []).some((linkedBuild) => linkedBuild.id === build.id);
const hasAccessToAllBuilds = group.attributes?.hasAccessToAllBuilds === true;
const testersResponse = await request(token, "GET", `/v1/betaGroups/${group.id}/relationships/betaTesters?limit=200`);
const testerCount = testersResponse.data?.length ?? 0;

if (mode === "assign" && !isInternalTestingAvailable) {
  fail(`Build ${build.id} internal state is ${internalBuildState ?? "missing"}; refusing assignment.`);
}
if (mode === "assign" && !alreadyLinked && !hasAccessToAllBuilds) {
  await request(token, "POST", `/v1/betaGroups/${group.id}/relationships/builds`, {
    data: [{ type: "builds", id: build.id }]
  });
}

const verifyResponse = await request(token, "GET", `/v1/betaGroups/${group.id}/relationships/builds?limit=200`);
const linked = (verifyResponse.data ?? []).some((linkedBuild) => linkedBuild.id === build.id);
if (mode === "assign" && !linked && !hasAccessToAllBuilds) {
  fail(`Build ${build.id} was not linked after the assignment request.`);
}

const status = !isInternalTestingAvailable
  ? `BLOCKED_${internalBuildState ?? "UNKNOWN_INTERNAL_STATE"}`
  : hasAccessToAllBuilds
    ? "AVAILABLE_AUTOMATICALLY"
    : linked
      ? "ASSIGNED"
      : "READY_TO_ASSIGN";

console.log(JSON.stringify({
  status,
  appId,
  bundleId,
  buildId: build.id,
  marketingVersion,
  buildNumber: build.attributes?.version,
  processingState,
  internalBuildState,
  externalBuildState,
  isInternalTestingAvailable,
  buildAudienceType: audience,
  usesNonExemptEncryption: build.attributes?.usesNonExemptEncryption ?? null,
  uploadedDate: build.attributes?.uploadedDate,
  groupId: group.id,
  groupName: group.attributes?.name,
  isInternalGroup: group.attributes?.isInternalGroup,
  hasAccessToAllBuilds,
  testerCount,
  publicLinkEnabled: group.attributes?.publicLinkEnabled,
  alreadyLinked,
  linked
}));

async function request(tokenValue, method, endpoint, body) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${endpoint}`, {
    method,
    headers: {
      Authorization: `Bearer ${tokenValue}`,
      ...(body ? { "Content-Type": "application/json" } : {})
    },
    body: body ? JSON.stringify(body) : undefined
  });
  const responseText = await response.text();
  const json = responseText ? JSON.parse(responseText) : {};
  if (!response.ok) {
    fail(`App Store Connect API failed ${method} ${endpoint}: ${response.status} ${responseText}`);
  }
  return json;
}

function createToken({ keyId: tokenKeyId, issuerId: tokenIssuerId, privateKey }) {
  const now = Math.floor(Date.now() / 1000);
  const input = `${base64url(JSON.stringify({ alg: "ES256", kid: tokenKeyId, typ: "JWT" }))}.${base64url(JSON.stringify({
    iss: tokenIssuerId,
    aud: "appstoreconnect-v1",
    exp: now + 19 * 60,
    iat: now
  }))}`;
  const signer = crypto.createSign("SHA256");
  signer.update(input);
  signer.end();
  const signature = signer.sign({ key: privateKey, dsaEncoding: "ieee-p1363" });
  return `${input}.${base64url(signature)}`;
}

function base64url(value) {
  const buffer = Buffer.isBuffer(value) ? value : Buffer.from(value);
  return buffer.toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function requiredEnvironment(name) {
  const value = process.env[name]?.trim();
  if (!value) fail(`Missing ${name}.`);
  return value;
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
