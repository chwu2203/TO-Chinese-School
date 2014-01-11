# encoding: utf-8
module Student::RegistrationHelper
  
  def display_string_for(school_class_type)
    return 'S(簡)' if school_class_type == SchoolClass::SCHOOL_CLASS_TYPE_SIMPLIFIED
    return 'T(繁)' if school_class_type == SchoolClass::SCHOOL_CLASS_TYPE_TRADITIONAL
    return 'SE(雙語)' if school_class_type == SchoolClass::SCHOOL_CLASS_TYPE_ENGLISH_INSTRUCTION
    school_class_type
  end
end
