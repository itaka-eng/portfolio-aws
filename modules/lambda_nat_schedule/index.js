// Lambda実行関数 NatGatewayを削除するNode.js
const AWS = require('aws-sdk'); //CommonJS(require)なのでESMインポートに移行必要
const { // utils.jsから関数を取得
  waitForNatGatewayDeletion,
  waitForNatGatewayAvailable,
  getNatGatewayIdByTag,
  getEipAllocationIdByTag
} = require('./utils');
const ec2 = new AWS.EC2();

exports.handler = async (event) => {
  const action = event.action;  // "start" or "stop" ←Lambda関数のinputで指定する

  try {
    if (action === "stop") {
      // NAT GatewayのIDを取得
      const natGatewayId = await getNatGatewayIdByTag("lambda-nat-gateway");
      if (!natGatewayId) {
        throw new Error("NAT Gateway not found");
      }

      // ルートテーブルからNAT Gatewayへのルートを削除
      try {
        await ec2.deleteRoute({
          RouteTableId: process.env.ROUTE_TABLE_ID,
          DestinationCidrBlock: "0.0.0.0/0"
        }).promise();
        console.log("Route to NAT Gateway deleted");
      } catch (e) {
        console.warn("Route deletion failed (possibly already deleted:)");
      }

      // NAT Gateway削除
      await ec2.deleteNatGateway({ NatGatewayId: natGatewayId }).promise();

      // NAT Gatewayが削除完了するまで待つ
      await waitForNatGatewayDeletion(natGatewayId);
      console.log(`Nat Gateway ${natGatewayId} stopped`);

      // EIPの割当ID取得と解放
      const allocationId = await getEipAllocationIdByTag("lambda-natgateway-eip");
      if (allocationId) {
        await ec2.releaseAddress({AllocationId: allocationId }).promise();
        console.log(`Elastic IP ${allocationId} released`);
      } else {
        console.warn("ALLOCATION_ID is not set, or EIP not released");
      }
    } else if (action === "start") {
      // Elastic IPを新規割当
      const eipResult = await ec2.allocateAddress({
        Domain: "vpc",
        TagSpecifications: [
          {
            ResourceType: "elastic-ip",
            Tags: [
              { Key: "Name", Value: "lambda-natgateway-eip"},
              { Key: "Description", Value: "Lambdaで自動生成 NAT Gateway用のElastic IP(固定グローバルIP)"},
              { Key: "Environment", Value: process.env.ENVIRONMENT || "dev"}
            ]
          }
        ]
      }).promise();
      console.log(`Elastic IP allocated: ${eipResult.AllocationId}`);

      // NAT Gatewayの作成
      const result = await ec2.createNatGateway({
        AllocationId: eipResult.AllocationId,
        SubnetId:     process.env.SUBNET_ID,
        TagSpecifications: [
          {
            ResourceType: "natgateway",
            Tags: [
              { Key: "Name", Value: "lambda-nat-gateway"},
              { Key: "Description", Value: "Lambdaで自動生成 パブリックサブネット(AZ:1a)に配置されたNAT Gateway"},
              { Key: "Environment", Value: process.env.ENVIRONMENT || "dev"}
            ]
          }
        ]
      }).promise();
      console.log(`NAT Gateway started: ${JSON.stringify(result)}`);

      // NAT Gatewayが利用可能になるまで待つ
      await waitForNatGatewayAvailable(result.NatGateway.NatGatewayId);

      // ルートテーブルにNAT Gatewayへのルートを追加
      await ec2.createRoute({
        RouteTableId: process.env.ROUTE_TABLE_ID,  // ルートテーブルIDはenvで渡す
        DestinationCidrBlock: "0.0.0.0/0",
        NatGatewayId: result.NatGateway.NatGatewayId
      }).promise();
      console.log(`Route added: 0.0.0.0/0 -> NAT Gateway ${result.NatGateway.NatGatewayId}`);

    } else {
      throw new Error(`Unknown action: ${action}`);
    }
  } catch (err) {
    console.error(err);
    throw err;
  }
};