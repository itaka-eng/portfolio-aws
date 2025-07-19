
const AWS = require('aws-sdk');
const ec2 = new AWS.EC2();

/**
 * NAT Gatewayが削除完了するまで最大3分間待機する関数
 * @param {string} natGatewayId - NAT GatewayのID
 * @returns {Promise<void>} 削除完了時は何も返さず、タイムアウト時は例外を投げる
 */
async function waitForNatGatewayDeletion(natGatewayId) {
  const maxRetries = 18;    // 3分
  for (let i = 0; i < maxRetries; i++) {
    const describe = await ec2.describeNatGateways({
      NatGatewayIds: [natGatewayId]
    }).promise();

    const state = describe.NatGateways[0]?.State;
    if (state === "deleted" || state === "failed" || !state) {
      return;
    }
    console.log(`Waiting for NAT Gateway deletion... (state: ${state})`);
    await new Promise(resolve => setTimeout(resolve, 10000));
  }
  throw new Error("Timeout: NAT Gateway was not deleted");
}

/**
 * NAT Gatewayが利用可能になるまで最大3分間待機する関数
 * @param {string} natGatewayId - NAT GatewayのID
 * @returns {Promise<void>} 利用可能時は何も返さず、タイムアウト時は例外を投げる
 */
async function waitForNatGatewayAvailable(natGatewayId) {
  const maxRetries = 30;    // 30回 * 10秒 = 5分 
  for (let i = 0; i < maxRetries; i++) {
    const describe = await ec2.describeNatGateways({
      NatGatewayIds: [natGatewayId]
    }).promise();

    const state = describe.NatGateways[0]?.State;
    if (state === "available") {
      console.log(`Nat Gateway is available: ${natGatewayId}`);
      return;
    } else if (state === "failed") {
      throw new Error(`NAT Gateway failed to become available: ${natGatewayId}`);
    } else if (!state) {
      throw new Error(`NAT Gateway state is undefined (ID: ${natGatewayId})`);
    } else {
      console.log(`Waiting for NAT Gateway to become available... (state: ${state})`);
    }
    await new Promise(resolve => setTimeout(resolve, 10000)); // 10秒待機
  }
  throw new Error("Timeout: NAT Gateway did not become available in time");
}

/**
 * 指定したタグ値でNAT GatewayのIDを取得する関数
 * @param {string} tagValue - NAT GatewayのNameタグ値
 * @returns {Promise<string|undefined>} NAT GatewayのID（見つからなければundefined）
 */
async function getNatGatewayIdByTag(tagValue) {
  console.log(`Searching for NAT Gateway with tag: ${tagValue}`);
  const response = await ec2.describeNatGateways({
    Filter: [
      { Name: "tag:Name", Values: [tagValue] },
      { Name: "state", Values: ["available", "pending"] }
    ]
  }).promise();
  const nat = response.NatGateways[0];
  console.log(`Found NAT Gateway: ${nat?.NatGatewayId}`);
  return nat?.NatGatewayId;
}

/**
 * 指定したタグ値でElastic IPのAllocationIdを取得する
 * @param {string} tagValue - Elastic IPのNameタグ値
 * @returns {Promise<string|undefined>} AllocationId（見つからなければundefined）
 */
async function getEipAllocationIdByTag(tagValue) {
  console.log(`Searching for Elastic IP with tag: ${tagValue}`);
  const response = await ec2.describeAddresses({
    Filters: [
      { Name: "tag:Name", Values: [tagValue] }
    ]
  }).promise();
  const eip = response.Addresses[0];
  console.log(`Found Elastic IP: ${eip?.AllocationId}`);
  return eip?.AllocationId;
}

module.exports = {
  waitForNatGatewayDeletion,
  waitForNatGatewayAvailable,
  getNatGatewayIdByTag,
  getEipAllocationIdByTag
};
