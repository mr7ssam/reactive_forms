// Copyright 2020 Joan Pablo Jiménez Milian. All rights reserved.
// Use of this source code is governed by the MIT license that can be
// found in the LICENSE file.

import 'package:reactive_forms/reactive_forms.dart';

/// Tracks the value and validity state of a group of FormControl instances.
///
/// A FormGroup aggregates the values of each child FormControl into one object,
/// with each control name as the key.
///
/// It calculates its status by reducing the status values of its children.
/// For example, if one of the controls in a group is invalid, the entire group
/// becomes invalid.
///
class FormGroup extends AbstractControl<Map<String, dynamic>> {
  final Map<String, AbstractControl> _controls;

  /// Creates a new FormGroup instance.
  ///
  /// When instantiating a [FormGroup], pass in a collection of child controls
  /// as the first argument.
  ///
  /// The key for each child registers the name for the control.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final form = FromGroup({
  ///   'name': FormControl(defaultValue: 'John Doe'),
  ///   'email': FormControl(),
  /// });
  /// ```
  /// You can also set [validators] as optionally argument.
  ///
  /// See also [FormGroup.validators]
  ///
  FormGroup(
    Map<String, AbstractControl> controls, {
    List<ValidatorFunction> validators,
    List<AsyncValidatorFunction> asyncValidators,
  })  : assert(controls != null),
        _controls = controls,
        super(
          validators: validators,
          asyncValidators: asyncValidators,
        ) {
    this.validate();
    _registerControlListeners();
  }

  /// Returns a [AbstractControl] by its name.
  AbstractControl formControl(String name) {
    return this._controls[name];
  }

  /// Returns the current value of the group.
  /// The values of controls as an object with
  /// a key-value pair for each control in the group.
  ///
  /// ### Example:
  ///
  ///```dart
  /// final form = FormGroup({
  ///   'name': FormControl(defaultValue: 'John Doe'),
  ///   'email': FormControl(defaultValue: 'johndoe@email.com'),
  /// });
  ///
  /// print(form.value);
  ///```
  ///
  /// ```json
  /// { "name": "John Doe", "email": "johndoe@email.com" }
  ///```
  ///
  Map<String, dynamic> get value {
    final map = Map<String, dynamic>();
    this._controls.forEach((key, formControl) {
      map[key] = formControl.value;
    });

    return map;
  }

  /// Set the complete value for the form group.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final form = FormGroup({
  ///   'name': FormControl(),
  ///   'email': FormControl(),
  /// });
  ///
  /// form.value = { 'name': 'John Doe', 'email': 'johndoe@email.com' }
  ///
  /// print(form.value);
  /// ```
  /// ```json
  /// { "name": "John Doe", "email": "johndoe@email.com" }
  ///```
  ///
  @override
  set value(Map<String, dynamic> newValue) {
    newValue.forEach((key, value) {
      if (this._controls.containsKey(key)) {
        this._controls[key].value = value;
      }
    });
  }

  /// Resets all the controls of the group, marking them as untouched,
  /// and setting the [FormControl.value] to [FormControl.defaultValue].
  ///
  /// See also [FormControl.reset()]
  ///
  @override
  void reset() {
    this._controls.forEach((key, formControl) {
      formControl.reset();
    });
  }

  void _registerControlListeners() {
    this._controls.values.forEach((control) {
      control.onValueChanged.addListener(_onControlValueChanged);
      control.onStatusChanged.addListener(_onControlStatusChanged);
    });
  }

  void _onControlValueChanged() {
    this.notifyValueChanged(this.value);
    this.validate();
  }

  void _onControlStatusChanged() {
    if (this.pending) {
      notifyStatusChanged(ControlStatus.pending);
    } else {
      this.validate();
    }
  }

  @override
  ControlStatus get status {
    final isPending = this._controls.values.any((control) => control.pending);
    if (isPending) {
      return ControlStatus.pending;
    }

    final isInvalid = this._controls.values.any((control) => control.invalid);
    return isInvalid ? ControlStatus.invalid : ControlStatus.valid;
  }

  @override
  void validate() {
    final errors = Map<String, dynamic>();

    this.validators.forEach((validator) {
      final error = validator(this);
      if (error != null) {
        errors.addAll(error);
      }
    });

    this._controls.forEach((key, control) {
      if (control.hasErrors) {
        errors.addAll({key: control.errors});
      }
    });

    this.setErrors(errors);
  }
}
