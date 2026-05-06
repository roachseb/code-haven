package com.example;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;

@Path("/api/tasks")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TaskResource {

    @GET
    public List<Task> list() {
        return Task.listAll();
    }

    @GET
    @Path("/{id}")
    public Task get(@PathParam("id") Long id) {
        Task task = Task.findById(id);
        if (task == null) {
            throw new NotFoundException("Task not found: " + id);
        }
        return task;
    }

    @POST
    @Transactional
    public Response create(Task task) {
        task.persist();
        return Response.status(Response.Status.CREATED).entity(task).build();
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Task update(@PathParam("id") Long id, Task update) {
        Task task = Task.findById(id);
        if (task == null) {
            throw new NotFoundException("Task not found: " + id);
        }
        task.title = update.title;
        task.description = update.description;
        task.completed = update.completed;
        return task;
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response delete(@PathParam("id") Long id) {
        boolean deleted = Task.deleteById(id);
        if (!deleted) {
            throw new NotFoundException("Task not found: " + id);
        }
        return Response.noContent().build();
    }
}
