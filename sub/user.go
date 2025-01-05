package main

import (
	"net/http"
	"strconv"
)

func GetUsers(w http.ResponseWriter, r *http.Request) {
	countRaw := r.PathValue("count")

	var count int
	var err error

	if countRaw == "" {
		count = 10
	} else {
		count, err = strconv.Atoi(countRaw)

		if err != nil {
			http.Error(w, "invalid count format", http.StatusBadRequest)
			return
		}
	}

	users, err := Users.ListUsers(count)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, users)
}

func FindUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")

	user, err := Users.FindUser(uuid)

	if user.UUID == "" {
		respondWithJSON(w, http.StatusOK, map[string]interface{}{"error": "Not Found"})
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, user)
}

type ICreateUser struct {
	Email        string `json:"email" validate:"required,email"`
	IsActive     bool   `json:"isActive" validate:"required"`
	TrafficLimit int    `json:"trafficLimit" validate:"required"`
	ResetPeriod  int    `json:"resetPeriod" validate:"required"`
}

func CreateUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")
	if !isValidUUID(uuid) {
		http.Error(w, "bad uuid format", http.StatusBadRequest)
		return
	}

	body, err := validateBody[ICreateUser](w, r)

	if err != nil {
		return
	}

	user, err := Users.CreateUser(uuid, body.Email, body.TrafficLimit, body.ResetPeriod)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, user)
}

type IUpdateUser struct {
	Email          string `json:"email" validate:"omitempty,email"`
	IsActive       bool   `json:"isActive"`
	CurrentTraffic int    `json:"currentTraffic"`
	TrafficLimit   int    `json:"trafficLimit"`
	ResetPeriod    int    `json:"resetPeriod"`
}

func UpdateUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")

	user, err := Users.FindUser(uuid)

	if user.UUID == "" {
		respondWithJSON(w, http.StatusOK, map[string]interface{}{"error": "Not Found"})
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	body, err := validateBody[IUpdateUser](w, r)

	if err != nil {
		return
	}

	mergeStructs(&user, &body)

	_, err = Users.UpdateUser(&user)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, user)
}

func DeleteUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")

	user, err := Users.FindUser(uuid)

	if user.UUID == "" {
		respondWithJSON(w, http.StatusOK, map[string]interface{}{"error": "Not Found"})
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	err = Users.DeleteUser(&user)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]interface{}{"status": "ok"})
}

func EnableUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")

	user, err := Users.FindUser(uuid)

	if user.UUID == "" {
		respondWithJSON(w, http.StatusOK, map[string]interface{}{"error": "Not Found"})
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	user.IsActive = true

	_, err = Users.UpdateUser(&user)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]interface{}{"status": "ok"})
}

func DisableUser(w http.ResponseWriter, r *http.Request) {
	uuid := r.PathValue("uuid")

	user, err := Users.FindUser(uuid)

	if user.UUID == "" {
		respondWithJSON(w, http.StatusOK, map[string]interface{}{"error": "Not Found"})
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	user.IsActive = false

	_, err = Users.UpdateUser(&user)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]interface{}{"status": "ok"})
}
