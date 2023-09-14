const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent function with the Functions Framework
functions.cloudEvent('startDataTransfer', cloudEvent => {  
  'use strict';

  function main() {
    // [START bigquerydatatransfer_v1_generated_DataTransferService_StartManualTransferRuns_async]
    
    // Imports the Datatransfer library
    const {DataTransferServiceClient} = require('@google-cloud/bigquery-data-transfer').v1;

    // Instantiates a client
    const dfClient = new DataTransferServiceClient();

    /**
     *  Transfer configuration name in the form:
     *  `projects/{project_id}/transferConfigs/{config_id}` or
     *  `projects/{project_id}/locations/{location_id}/transferConfigs/{config_id}`.
     */
    const parent = process.env.TRANSFER_ID;
    console.log(`Parent: ${parent}`);

    async function callStartManualTransferRuns() {
      // Construct request
      const request = {
        parent: parent,
        requestedRunTime: {
          seconds: Math.floor(new Date().getTime() / 1000),
        },
      };

      // Run request
      const response = await dfClient.startManualTransferRuns(request);
      console.log(response);
    }

    callStartManualTransferRuns();
    // [END bigquerydatatransfer_v1_generated_DataTransferService_StartManualTransferRuns_async]
  }

  process.on('unhandledRejection', err => {
    console.error(err.message);
    process.exitCode = 1;
  });
  main(...process.argv.slice(2));
});

