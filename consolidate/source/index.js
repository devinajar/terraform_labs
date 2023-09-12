// BASED ON CODE FROM: https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv#loading_csv_data_into_a_table

// Import the GCP client libraries
const functions = require('@google-cloud/functions-framework');
const {BigQuery} = require('@google-cloud/bigquery');
const {Storage} = require('@google-cloud/storage');

// Initiate clients
const bigquery = new BigQuery();
const storage = new Storage();

functions.cloudEvent('loadCSVFromGCS', event => {
  // Variables for bucket and file name
  const bucketName = event.bucket;
  const filename = event.data.name;

  // Variables for the Dataset and table where the data will be loaded
  const datasetPath = process.env.DATASET_ID.split("/"); 
  const datasetId = datasetPath[datasetPath.length -1];
  const tableId = process.env.TABLE_ID;

  // Data loading job configuration
  // Omitting schema since it's already declared in the destination table
  const metadata = {
    sourceFormat: 'CSV',
    skipLeadingRows: 1,
    location: process.env.REGION,
    // Set the write disposition to overwrite existing table data.
    writeDisposition: 'WRITE_TRUNCATE',
  };
  
  // Job to load data from a GCS into a table
  bigquery
  .dataset(datasetId)
  .table(tableId)
  .load(storage.bucket(bucketName).file(filename), metadata)
  .then(() => {
    // load() waits for the job to finish
    console.log(`Loaded ${filename} to ${datasetId}.${tableId}`);
  })
  .catch(err =>{
    console.log('Error loading file into BigQuery:', err);
  })
});