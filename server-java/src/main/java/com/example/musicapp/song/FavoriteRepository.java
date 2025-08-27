package com.example.musicapp.song;

import com.example.musicapp.song.model.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, String> {
    Optional<Favorite> findByUserIdAndSongId(String userId, String songId);
    List<Favorite> findAllByUserId(String userId);
}