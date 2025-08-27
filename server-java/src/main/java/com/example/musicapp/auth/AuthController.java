package com.example.musicapp.auth;

import com.example.musicapp.auth.dto.LoginRequest;
import com.example.musicapp.auth.dto.LoginResponse;
import com.example.musicapp.auth.dto.SignUpRequest;
import com.example.musicapp.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<User> signupUser(@RequestBody SignUpRequest signUpRequest) {
        User createdUser = authService.signUp(signUpRequest);
        return new ResponseEntity<>(createdUser, HttpStatus.CREATED);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> loginUser(@RequestBody LoginRequest loginRequest) {
        LoginResponse response = authService.login(loginRequest);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<User> currentUserData() {
        User currentUser = authService.getCurrentUser();
        return ResponseEntity.ok(currentUser);
    }
}