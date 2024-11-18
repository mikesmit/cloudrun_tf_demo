import express, { Request, response } from 'express';
import { convert } from './puppet';
import { Storage } from '@google-cloud/storage';
import { CloudTasksClient } from '@google-cloud/tasks';
/**
 * Simple demonstration of using an API endpoint to generate a task that async
 * renders an scg using puppeteer, stores the result in a bucket, and
 * allows the user to get the result from the bucket
 */

const app = express();
type RequestType = {
    id:string
};
app.use(express.json())


const tasksClient = new CloudTasksClient();

app.get("/ping", async(req, res)=>{
    res.send("OK")
})

app.post('/task', async(req:Request<{},{}, RequestType>, res)=> {
    console.log("Generating task");
    const {id} = req.body;
    try {
        //TODO: change this to a buffer task with queue level routing.
        //No reason to redefine this every time.
        //TODO: inject configuration of project/queue/etc. in by env variables.
        const [task, ..._] = await tasksClient.createTask({
            parent: tasksClient.queuePath("calm-vehicle-441017-f9", "us-west2", "test-app-queue"),
            task:{
                httpRequest: {
                    url:   'https://testgooglerun-694318849462.us-west2.run.app/snapshot_task',
                    httpMethod: 'POST',
                    headers:{
                        'Content-Type':'application/json'
                    },
                    body:Buffer.from(JSON.stringify({id})).toString("base64"), //https://github.com/googleapis/nodejs-tasks/issues/606,
                    oidcToken: {
                        serviceAccountEmail:"task-service-account@calm-vehicle-441017-f9.iam.gserviceaccount.com"
                    }
                }
            }
        })
        console.log(`Task created with name ${task.name}`)
    } catch (e) {
        console.error(`Task creation failed: ${e}`)
        throw e;
    }
    console.log()
    res.send("OK")
});


const storage = new Storage();
const bucket = storage.bucket("calm-vehicle-441017-f9-social-images");

app.post('/snapshot_task', async (req:Request<{},{}, RequestType>, res) => {
    console.log(`req is ${JSON.stringify(req.body)}`);
    const {id} = req.body;
    console.log(`Got request for id ${id}`)
    console.log("Rendering image with puppetter")
    const result = await convert(`<svg xmlns="http://www.w3.org/2000/svg"
        width="526" height="233">
    <rect x="13" y="14" width="500" height="200" rx="50" ry="100"
        fill="none" stroke="blue" stroke-width="10" />
  </svg>`)
    const buffer = Buffer.from(result);
    console.log(`Uploading image to ${bucket.name}/cache/${id}.jpg`);
    //https://github.com/googleapis/nodejs-storage/blob/main/samples/uploadFromMemory.js
    const file = bucket.file(`cache/${id}.jpeg`);
    try {
    await file.save(buffer)
    } catch (e) {
    console.error(`Failed to save result to bucket: ${e}`)
    throw e;
    }
    console.log("Success!")
    res.send("OK");
});

const port = process.env.PORT ? parseInt(process.env.PORT) : 8080;
console.log("starting app...");
app.listen(port, () => {
  console.log(`helloworld: listening on port ${port}`);
});
