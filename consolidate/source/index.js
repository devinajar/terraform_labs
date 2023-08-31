const functions = require('@google-cloud/functions-framework');
const bigqueryDataTransfer = require('@google-cloud/bigquery-data-transfer');
const client = new bigqueryDataTransfer.v1.DataTransferServiceClient();

functions.cloudEvent('quickstart', cloudEvent => {
  const projectId = "labs-for-ltech";
  const transferId = client.getTransferConfig();
  parent = client.projectTransferConfigPath(projectId, transferId)

  response = client.startManualTransferRuns(parent);
});