import puppeteer, {Browser} from 'puppeteer';

/**
 * Simple demonstration of rendering an SVG using puppeteer.
 * @param svg 
 * @returns 
 */
export async function convert(svg:string) {
    //looks like we run as root by default and puppeteer will refuse to start in that case without
    //--no-sandbox
    const puppet = await puppeteer.launch({ args: ['--no-sandbox'], });
    try {
        const page = await puppet.newPage();
        const html = `<!DOCTYPE html>
        <html>
        <head>
            <style>
            * {margin: 0, padding: 0}
            </style>
        </head>
        <body>
            ${svg}
        </body>
        </html>`
        await page.setContent(html,  { waitUntil: ['load'], timeout:5000});
        await page.setViewport({height:300, width:300});

        const output = await page.screenshot({
            type:"jpeg",
            omitBackground:true
        });

        await page.close();
        return output;
    } finally {
        puppet.close();
    }
}