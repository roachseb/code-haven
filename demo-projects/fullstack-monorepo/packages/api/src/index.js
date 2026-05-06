const fastify = require("fastify")({ logger: true });
const cors = require("@fastify/cors");

fastify.register(cors, { origin: process.env.FRONTEND_URL || "http://localhost:3000" });

fastify.get("/api/health", async () => ({ status: "ok", service: "api" }));

fastify.get("/api/items", async () => [
  { id: 1, name: "Item One", status: "active" },
  { id: 2, name: "Item Two", status: "pending" },
  { id: 3, name: "Item Three", status: "active" },
]);

const start = async () => {
  const port = process.env.PORT || 4000;
  await fastify.listen({ port, host: "0.0.0.0" });
};
start();
