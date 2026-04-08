package com.myapp.hello;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, Object> index() {
        return Map.of(
            "message", "Hello from MyApp CI/CD Pipeline!",
            "status",  "UP",
            "timestamp", Instant.now().toString()
        );
    }

    @GetMapping("/hello/{name}")
    public Map<String, String> greet(@PathVariable String name) {
        return Map.of("greeting", "Hello, " + name + "! 👋");
    }
}
