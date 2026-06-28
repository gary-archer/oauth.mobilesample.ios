import express from 'express';
import fs from 'fs';
import https from 'https';

const staticOptions = {
    setHeaders(response) {
        response.set('Content-Type', 'application/json');
    },
};

const expressApp = express();
expressApp.use('/.well-known', express.static('./.well-known', staticOptions));

const pfxFile = fs.readFileSync('./certs/mobile.authsamples.ssl.p12');
const serverOptions = {
    pfx: pfxFile,
    passphrase: 'Password1',
};

const port = 443;
const httpsServer = https.createServer(serverOptions, expressApp);
httpsServer.listen(port, () => {
    console.log(`Mobile host is listening on HTTPS port ${port}`);
});
