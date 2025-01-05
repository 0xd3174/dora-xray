package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/go-playground/validator/v10"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var Users UsersRepository

func main() {
	db, err := gorm.Open(sqlite.Open("dora-xray.db"), &gorm.Config{})

	if err != nil {
		panic("Failed to connect database")
	}

	db.AutoMigrate(&User{})

	Users = UsersRepository{db: db}

	http.HandleFunc("GET /users/{count}", GetUsers)
	http.HandleFunc("GET /user/{uuid}", FindUser)
	http.HandleFunc("POST /create/{uuid}", CreateUser)
	http.HandleFunc("POST /update/{uuid}", UpdateUser)
	http.HandleFunc("POST /delete/{uuid}", DeleteUser)
	http.HandleFunc("POST /enable/{uuid}", EnableUser)
	http.HandleFunc("POST /disable/{uuid}", DisableUser)

	// http.HandleFunc("GET /xray/{uuid}", nil)
	// http.HandleFunc("GET /vless/{uuid}", nil)
	// http.HandleFunc("GET /sing-box/{uuid}", nil)
	// http.HandleFunc("GET /clash/{uuid}", nil)

	http.HandleFunc("GET /", Index)

	http.ListenAndServe(":8444", nil)
}

func validateBody[T any](w http.ResponseWriter, r *http.Request) (T, error) {
	var err error

	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Content Type is not application/json", http.StatusUnsupportedMediaType)
	}

	var body T
	decoder := json.NewDecoder(r.Body)
	if err = decoder.Decode(&body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

	validate := validator.New()
	if err = validate.Struct(body); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

	return body, err
}

func respondWithJSON(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(payload); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func Index(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "🪣 How Did We Get Here?")
}
