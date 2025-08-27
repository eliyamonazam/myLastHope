package com.example.musicapp.song;

import com.example.musicapp.song.dto.FavoriteRequest;
import com.example.musicapp.song.model.Favorite;
import com.example.musicapp.song.model.Song;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/song")
public class SongController {

    @Autowired
    private SongService songService;

    // API برای جستجو
    @GetMapping("/search")
    public ResponseEntity<List<Song>> searchSongs(
            @RequestParam("query") String query,
            @RequestParam(value = "type", defaultValue = "songName") String type) {
        List<Song> songs = songService.searchSongs(query, type);
        return ResponseEntity.ok(songs);
    }
    
    // API برای آپلود (فعال شده)
    @PostMapping("/upload")
    public ResponseEntity<Song> uploadSong(
            @RequestParam("song") MultipartFile songFile,
            @RequestParam("thumbnail") MultipartFile thumbnailFile,
            @RequestParam("artist") String artist,
            @RequestParam("song_name") String songName,
            @RequestParam("hex_code") String hexCode) throws IOException {

        Song newSong = songService.upload(songFile, thumbnailFile, artist, songName, hexCode);
        return new ResponseEntity<>(newSong, HttpStatus.CREATED);
    }

    // API برای لیست کردن همه آهنگ‌ها
    @GetMapping("/list")
    public ResponseEntity<List<Song>> listSongs() {
        List<Song> songs = songService.getAllSongs();
        return ResponseEntity.ok(songs);
    }

    // API برای علاقه‌مندی‌ها
    @PostMapping("/favorite")
    public ResponseEntity<Map<String, Boolean>> favoriteSong(@RequestBody FavoriteRequest favoriteRequest) {
        boolean isFavorited = songService.toggleFavorite(favoriteRequest.getSongId());
        return ResponseEntity.ok(Map.of("isFavorited", isFavorited));
    }

    // API برای گرفتن لیست علاقه‌مندی‌ها
    @GetMapping("/list/favorites")
    public ResponseEntity<List<Favorite>> listFavoriteSongs() {
        List<Favorite> favoriteSongs = songService.getFavoriteSongs();
        return ResponseEntity.ok(favoriteSongs);
    }
}