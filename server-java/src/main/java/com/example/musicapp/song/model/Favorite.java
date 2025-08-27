package com.example.musicapp.song.model;

import com.example.musicapp.user.User;
import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;

@Entity
@Table(name = "favorites")
public class Favorite {

    @Id
    @Column(columnDefinition = "TEXT") // <-- The fix is here
    private String id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "song_id")
    private Song song;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    @JsonBackReference
    private User user;

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Song getSong() { return song; }
    public void setSong(Song song) { this.song = song; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
}