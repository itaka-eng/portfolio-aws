// NAT Gatewayが削除完了するまで待つ処理

const AWS = require('aws-sdk');
const ec2 = new AWS.EC2();

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

module.exports = {
  waitForNatGatewayDeletion
};