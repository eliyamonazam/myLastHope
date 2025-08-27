package com.example.musicapp.song;

import com.example.musicapp.song.model.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SongRepository extends JpaRepository<Song, String> {
    
    // متد جدید برای جستجو بر اساس نام آهنگ (بدون حساسیت به بزرگی و کوچکی حروف)
    List<Song> findBySongNameContainingIgnoreCase(String songName);

    // متد جدید برای جستجو بر اساس نام خواننده (بدون حساسیت به بزرگی و کوچکی حروف)
    List<Song> findByArtistContainingIgnoreCase(String artist);
}