package io.featurehub.db.api;

import io.featurehub.mr.model.Person;

import java.time.LocalDateTime;

public class DBLoginSession {
  private Person person;
  private String token;
  private LocalDateTime lastSeen;

  public DBLoginSession(Person person, String token, LocalDateTime lastSeen) {
    this.person = person;
    this.token = token;
    this.lastSeen = lastSeen;
  }

  public Person getPerson() {
    return person;
  }

  public String getToken() {
    return token;
  }

  public LocalDateTime getLastSeen() {
    return lastSeen;
  }
}
