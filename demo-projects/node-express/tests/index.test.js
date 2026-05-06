const request = require('supertest');
const app = require('../src/index');

describe('API Endpoints', () => {
    test('GET / returns hello message', async () => {
        const res = await request(app).get('/');
        expect(res.status).toBe(200);
        expect(res.body.version).toBe('1.0.0');
    });

    test('GET /health returns healthy', async () => {
        const res = await request(app).get('/health');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('healthy');
    });

    test('GET /add/:a/:b returns sum', async () => {
        const res = await request(app).get('/add/3/7');
        expect(res.status).toBe(200);
        expect(res.body.result).toBe(10);
    });
});
