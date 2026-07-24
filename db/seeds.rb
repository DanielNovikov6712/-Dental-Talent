skills_by_group = {
  "dentist"           => [ "Endodontics", "Restorative dentistry", "Pediatric dentistry", "Surgery", "Aligners" ],
  "dental_hygienist"  => [ "Periodontology", "Prevention", "Scaling", "Patient education" ],
  "dental_assistant"  => [ "Chairside assistance", "Sterilization", "Orthodontics", "Prevention" ],
  "front_office"      => [ "Planning", "Phone handling", "Invoicing", "Patient communication" ],
  "practice_manager"  => [ "Team management", "Scheduling", "HR", "Practice operations" ],
  "dental_technician" => [ "Prosthetics", "CAD/CAM", "Crown and bridge work" ]
}

skills_by_group.each do |group, names|
  names.each_with_index do |name, index|
    skill = Skill.find_or_initialize_by(function_group: group, name: name)
    skill.update!(position: index)
  end
end

languages = {
  "Dutch" => "nl", "English" => "en", "German" => "de", "French" => "fr",
  "Spanish" => "es", "Italian" => "it", "Polish" => "pl", "Portuguese" => "pt",
  "Turkish" => "tr", "Arabic" => "ar", "Ukrainian" => "uk", "Russian" => "ru"
}

languages.each_with_index do |(name, code), index|
  language = Language.find_or_initialize_by(name: name)
  language.update!(code: code, position: index)
end

unless Rails.env.production?
  {
    "admin@example.com"     => "admin",
    "recruiter@example.com" => "recruiter"
  }.each do |email, role|
    user = User.find_or_initialize_by(email_address: email)
    user.role = role
    user.password = "password123" if user.new_record?
    user.save!
  end
end

puts "Seeded #{Skill.count} skills and #{Language.count} languages."
