const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;

// main page
app.get('/', (_req, res) => {
  res.send('CloudCart is up! 🚀');
});

// health check endpoint
app.get('/healthz', (_req, res) => {
  res.status(200).send('ok');
});

app.listen(PORT, () => {
  console.log(`CloudCart listening on port ${PORT}`);
});

