const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.send('AWS DevOps Pipeline Deployed Successfully on EC2 via Terraform + Jenkins + Docker!');
});

app.listen(PORT, () => {
  console.log(Server running on port ${PORT});
});
