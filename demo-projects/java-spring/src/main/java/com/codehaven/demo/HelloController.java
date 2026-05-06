package com.codehaven.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, String> root() {
        return Map.of(
            "message", "Hello from Code Haven Java demo!",
            "version", "1.0.0"
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "healthy");
    }

    @GetMapping("/add/{a}/{b}")
    public Map<String, Integer> add(@PathVariable int a, @PathVariable int b) {
        return Map.of("result", a + b);
    }
}
