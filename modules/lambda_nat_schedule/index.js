// Lambda実行関数 NatGatewayを削除するNode.js
// 当スクリプト(と必要pkg)をlambda.zipとして圧縮する zip -r lambda.zip index.js utils.js node_modules/ package.json 
// Node.js ver.18からAWS SDKを同梱する必要ある→当ディレクトリでnpm install aws-sdkして、lambda.zipにnode_modulesを含めること 
// ↓手動実行方法（AWS CLI）
// aws lambda invoke --function-name nat-gateway-scheduler --payload '{"action":"stop"}' --cli-binary-format raw-in-base64-out result.json
const AWS = require('aws-sdk'); //CommonJS(require)なのでESMインポートに移行必要
const { waitForNatGatewayDeletion } = require('./utils');
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
      // NAT Gateway 停止（削除）
      await ec2.deleteNatGateway({ NatGatewayId: natGatewayId }).promise();
      console.log(`Nat Gateway ${natGatewayId} stopped`);

      // NAT Gatewayが削除完了するまで待つ処理を呼び出し(utils.js)
      await waitForNatGatewayDeletion(natGatewayId);

      // EIPの割当IDを取得
      const allocationId = process.env.ALLOCATION_ID;
      if (allocationId) {
        //// 10秒待機（NAT Gateway削除後すぐはエラーになるため）          // 別関数にしたのでコメントアウト
        //await new Promise(resolve => setTimeout(resolve, 10000)); // 別関数にしたのでコメントアウト
        // EIP割当開放
        await ec2.releaseAddress({AllocationId: allocationId }).promise();
        console.log(`Elastic IP ${allocationId} released`);
      } else {
        console.warn("ALLOCATION_ID is not set, os EIP not released");
      }
    } else if (action === "start") {
      // NAT Gateway 開始（作成）
      //const allocationId = process.env.ALLOCATION_ID; // start時にEIPを再取得するのでコメントアウト
      const subnetId = process.env.SUBNET_ID;

      // Elastic IPを再取得
      const eipResult = await ec2.allocateAddress({
        Domain: "vpc",
        TagSpecifications: [
          {
            ResourceType: "elastic-ip",
            Tags: [
              { Key: "Name", Value: "natgateway-eip"},
              { Key: "Description", Value: "Lambdaで自動生成 NAT Gateway用のElastic IP(固定グローバルIP)"},
              { Key: "Environment", Value: process.env.ENVIRONMENT || "dev"}
            ]
          }
        ]
      }).promise();
      const allocationId = eipResult.AllocationId;

      const result = await ec2.createNatGateway({
        AllocationId: allocationId,
        SubnetId: subnetId,
        TagSpecifications: [
          {
            ResourceType: "natgateway",
            Tags: [
              { Key: "Name", Value: "nat-gateway"},
              { Key: "Description", Value: "Lambdaで自動生成 パブリックサブネット(AZ:1a)に配置されたNAT Gateway"},
              { Key: "Environment", Value: process.env.ENVIRONMENT || "dev"}
            ]
          }
        ]
      }).promise();
      console.log(`NAT Gateway started: ${JSON.stringify(result)}`);
      console.log(`Elastic IP allocated: ${allocationId}`);
    } else {
      throw new Error(`Unknown action: ${action}`);
    }
  } catch (err) {
    console.error(err);
    throw err;
  }
};