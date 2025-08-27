package com.example.musicapp.song;

import com.cloudinary.Cloudinary;
import com.example.musicapp.song.model.Favorite;
import com.example.musicapp.song.model.Song;
import com.example.musicapp.user.User;
import com.example.musicapp.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;


@Service
public class SongService {

    @Autowired
    private Cloudinary cloudinary;
    @Autowired
    private SongRepository songRepository;
    @Autowired
    private FavoriteRepository favoriteRepository;
    @Autowired
    private UserRepository userRepository;

    public List<Song> searchSongs(String query, String type) {
        if (query == null || query.trim().isEmpty()) {
            return new ArrayList<>();
        }

        if ("artist".equalsIgnoreCase(type)) {
            return songRepository.findByArtistContainingIgnoreCase(query);
        } else {
            return songRepository.findBySongNameContainingIgnoreCase(query);
        }
    }

    public Song upload(MultipartFile songFile, MultipartFile thumbnailFile, String artist, String songName, String hexCode) throws IOException {
        Map songUploadResult = cloudinary.uploader().upload(songFile.getBytes(), Map.of("resource_type", "video", "secure", true));
        Map thumbnailUploadResult = cloudinary.uploader().upload(thumbnailFile.getBytes(), Map.of("resource_type", "image", "secure", true));

        Song newSong = new Song();
        newSong.setId(UUID.randomUUID().toString());
        newSong.setArtist(artist);
        newSong.setSongName(songName);
        newSong.setHexCode(hexCode);
        newSong.setSongUrl((String) songUploadResult.get("url"));
        newSong.setThumbnailUrl((String) thumbnailUploadResult.get("url"));

        return songRepository.save(newSong);
    }

    public List<Song> getAllSongs() {
        return songRepository.findAll();
    }

    public boolean toggleFavorite(String songId) {
        User currentUser = getCurrentUser();
        Optional<Favorite> favorite = favoriteRepository.findByUserIdAndSongId(currentUser.getId(), songId);

        if (favorite.isPresent()) {
            favoriteRepository.delete(favorite.get());
            return false;
        } else {
            Song song = songRepository.findById(songId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Song not found"));

            Favorite newFavorite = new Favorite();
            newFavorite.setId(UUID.randomUUID().toString());
            newFavorite.setUser(currentUser);
            newFavorite.setSong(song);
            favoriteRepository.save(newFavorite);
            return true;
        }
    }

    public List<Favorite> getFavoriteSongs() {
        User currentUser = getCurrentUser();
        return favoriteRepository.findAllByUserId(currentUser.getId());
    }

    private User getCurrentUser() {
        String userEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Current user not found"));
    }
}