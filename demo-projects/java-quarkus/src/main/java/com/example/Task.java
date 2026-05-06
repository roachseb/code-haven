package com.example;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
@Table(name = "tasks")
public class Task extends PanacheEntity {
    public String title;
    public String description;
    public boolean completed;
}
