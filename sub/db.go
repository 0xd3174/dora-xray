package main

import (
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	UUID           string `json:"id" gorm:"primaryKey;column:uuid;autoIncrement:false"`
	Email          string `json:"email"`
	IsActive       bool   `json:"isActive"`
	CurrentTraffic int    `json:"currentTraffic"`
	TrafficLimit   int    `json:"trafficLimit"`
	ResetPeriod    int    `json:"resetPeriod"`
}

type UsersRepository struct {
	db *gorm.DB
}

func (u UsersRepository) FindUser(uuid string) (User, error) {
	var user User

	err := u.db.Where("uuid = ?", uuid).Find(&user).Error

	return user, err
}

func (u UsersRepository) ListUsers(count int) ([]User, error) {
	var users []User

	err := u.db.Limit(count).Find(&users).Error

	return users, err
}

func (u UsersRepository) CreateUser(uuid string, email string, trafficLimit int, resetPeriod int) (User, error) {
	user := User{
		UUID:           uuid,
		Email:          email,
		IsActive:       true,
		CurrentTraffic: 0,
		TrafficLimit:   trafficLimit,
		ResetPeriod:    resetPeriod,
	}

	result := u.db.Create(&user)

	return user, result.Error
}

func (u UsersRepository) UpdateUser(user *User) (*User, error) {
	result := u.db.Model(&User{}).Where("uuid = ?", user.UUID).Save(user)

	return user, result.Error
}

func (u UsersRepository) DeleteUser(user *User) error {
	err := u.db.Where("uuid = ?", user.UUID).Delete(&User{}).Error

	return err
}
