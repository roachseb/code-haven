package com.example;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
class TaskResourceTest {

    @Test
    void testListTasks() {
        given()
            .when().get("/api/tasks")
            .then()
            .statusCode(200);
    }

    @Test
    void testCreateAndGetTask() {
        // Create a task
        Integer id = given()
            .contentType("application/json")
            .body("{\"title\":\"Test task\",\"description\":\"Testing\",\"completed\":false}")
            .when().post("/api/tasks")
            .then()
            .statusCode(201)
            .body("id", notNullValue())
            .extract().path("id");

        // Get the task
        given()
            .when().get("/api/tasks/" + id)
            .then()
            .statusCode(200);
    }
}
