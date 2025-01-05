package main

import (
	"reflect"
	"regexp"
)

func isValidUUID(uuid string) bool {
	re := regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89abAB][a-f0-9]{3}-[a-f0-9]{12}$`)
	return re.MatchString(uuid)
}

func mergeStructs(target interface{}, source interface{}) {
	targetVal := reflect.ValueOf(target).Elem()
	sourceVal := reflect.ValueOf(source).Elem()

	for i := 0; i < sourceVal.NumField(); i++ {
		sourceField := sourceVal.Type().Field(i)
		sourceValue := sourceVal.Field(i)

		targetField := targetVal.FieldByName(sourceField.Name)
		if targetField.IsValid() && targetField.CanSet() {
			if targetField.Type() == sourceValue.Type() {
				targetField.Set(sourceValue)
			}
		}
	}
}
