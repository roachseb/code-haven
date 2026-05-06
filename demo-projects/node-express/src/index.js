const express = require('express');

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'Hello from Code Haven Node.js demo!', version: '1.0.0' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.get('/add/:a/:b', (req, res) => {
    const a = parseInt(req.params.a, 10);
    const b = parseInt(req.params.b, 10);
    res.json({ result: a + b });
});

// Only start server if not in test mode
if (process.env.NODE_ENV !== 'test') {
    const port = process.env.PORT || 3000;
    app.listen(port, () => {
        console.log(`🚀 Server running on port ${port}`);
    });
}

module.exports = app;
