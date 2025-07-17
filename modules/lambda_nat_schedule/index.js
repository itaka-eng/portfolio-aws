// Lambda実行関数 NatGatewayを削除するNode.js
// 当スクリプトをlambda.zipとして圧縮する
// Node.js ver.18からAWS SDKを同梱する必要ある→当ディレクトリでnpm install aws-sdkして、lambda.zipにnode_modulesを含めること 
// ↓手動実行方法（AWS CLI）
// aws lambda invoke --function-name nat-gateway-scheduler --payload '{"action":"stop"}' --cli-binary-format raw-in-base64-out result.json
const AWS = require('aws-sdk'); //CommonJS(require)なのでESMインポートに移行必要、
const ec2 = new AWS.EC2();

exports.handler = async (event) => {
  const action = event.action;  // "start" or "stop" ←Lambda関数のinputで指定する
  const natGatewayId = process.env.NAT_GATEWAY_ID;

  // NAT_GATEWAY_IDがない場合エラーを返す
  if (!natGatewayId) {
    throw new Error("NAT_GATEWAY_ID is not set");
  }

  try {
    if (action === "stop") {
      // 停止（削除）
      await ec2.deleteNatGateway({ NatGatewayId: natGatewayId }).promise();
      console.log(`Nat Gateway ${natGatewayId} stopped`);
    } else if (action === "start") {
      // 開始（作成）
      const allocationId = process.env.ALLOCATION_ID;
      const subnetId = process.env.SUBNET_ID;

      const result = await ec2.createNatGateway({
        AllocationId: allocationId,
        SubnetId: subnetId
      }).promise();
      console.log(`NAT Gateway started: ${JSON.stringify(result)}`);
    } else {
      throw new Error(`Unknown action: ${action}`);
    }
  } catch (err) {
    console.error(err);
    throw err;
  }
};