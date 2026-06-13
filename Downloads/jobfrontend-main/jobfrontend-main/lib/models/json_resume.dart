/// Represents the standard JSON Resume schema (jsonresume.org).
class JsonResume {
  final Basics basics;
  final List<Work> work;
  final List<Volunteer> volunteer;
  final List<Education> education;
  final List<Award> awards;
  final List<Publication> publications;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;
  final List<Reference> references;

  /// Optional headline for Priority-style PDF (e.g. "1 Year 6 months").
  String totalWorkExperience;

  JsonResume({
    Basics? basics,
    List<Work>? work,
    List<Volunteer>? volunteer,
    List<Education>? education,
    List<Award>? awards,
    List<Publication>? publications,
    List<Skill>? skills,
    List<Language>? languages,
    List<Interest>? interests,
    List<Reference>? references,
    String? totalWorkExperience,
  })  : basics = basics ?? Basics(),
        work = work ?? [],
        volunteer = volunteer ?? [],
        education = education ?? [],
        awards = awards ?? [],
        publications = publications ?? [],
        skills = skills ?? [],
        languages = languages ?? [],
        interests = interests ?? [],
        references = references ?? [],
        totalWorkExperience = totalWorkExperience ?? '';

  factory JsonResume.fromJson(Map<String, dynamic> json) {
    List<Work>? workList;
    if (json['work'] != null) {
      workList = List<Work>.from(
        (json['work'] as List).map((x) => Work.fromJson(Map<String, dynamic>.from(x as Map))),
      );
    }
    if ((workList == null || workList.isEmpty) && json['experience'] != null) {
      workList = List<Work>.from(
        (json['experience'] as List).map((x) => Work.fromJson(Map<String, dynamic>.from(x as Map))),
      );
    }

    List<Publication>? pubList;
    if (json['publications'] != null) {
      pubList = List<Publication>.from(
        (json['publications'] as List).map((x) => Publication.fromJson(Map<String, dynamic>.from(x as Map))),
      );
    }
    if ((pubList == null || pubList.isEmpty) && json['projects'] != null) {
      pubList = List<Publication>.from(
        (json['projects'] as List).map((x) => Publication.fromJson(Map<String, dynamic>.from(x as Map))),
      );
    }

    List<Skill>? skillList;
    if (json['skills'] != null) {
      skillList = List<Skill>.from(
        (json['skills'] as List).map((x) {
          if (x is String) return Skill(name: x);
          return Skill.fromJson(Map<String, dynamic>.from(x as Map));
        }),
      );
    }

    return JsonResume(
      basics: json['basics'] != null ? Basics.fromJson(json['basics']) : null,
      work: workList,
      volunteer: json['volunteer'] != null
          ? List<Volunteer>.from(
              json['volunteer'].map((x) => Volunteer.fromJson(x)))
          : null,
      education: json['education'] != null
          ? List<Education>.from(
              json['education'].map((x) => Education.fromJson(x)))
          : null,
      awards: json['awards'] != null
          ? List<Award>.from(json['awards'].map((x) => Award.fromJson(x)))
          : null,
      publications: pubList,
      skills: skillList,
      languages: json['languages'] != null
          ? List<Language>.from(
              json['languages'].map((x) => Language.fromJson(x)))
          : null,
      interests: json['interests'] != null
          ? List<Interest>.from(
              json['interests'].map((x) => Interest.fromJson(x)))
          : null,
      references: json['references'] != null
          ? List<Reference>.from(
              json['references'].map((x) => Reference.fromJson(x)))
          : null,
      totalWorkExperience: json['totalWorkExperience']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basics': basics.toJson(),
      'work': work.map((x) => x.toJson()).toList(),
      'volunteer': volunteer.map((x) => x.toJson()).toList(),
      'education': education.map((x) => x.toJson()).toList(),
      'awards': awards.map((x) => x.toJson()).toList(),
      'publications': publications.map((x) => x.toJson()).toList(),
      'skills': skills.map((x) => x.toJson()).toList(),
      'languages': languages.map((x) => x.toJson()).toList(),
      'interests': interests.map((x) => x.toJson()).toList(),
      'references': references.map((x) => x.toJson()).toList(),
      'totalWorkExperience': totalWorkExperience,
    };
  }

  factory JsonResume.mock() {
    return JsonResume(
      basics: Basics(
        name: 'John Doe',
        label: 'Senior Software Engineer',
        summary: 'Experienced developer with a passion for clean code and modern UI. Expert at building scalable mobile applications and designer-grade user interfaces.',
        email: 'john.doe@example.com',
        phone: '+1 234 567 890',
      ),
      work: [
        Work(name: 'Tech Giant Inc.', position: 'Senior Flutter Developer', startDate: '2021-01-01', summary: 'Architected the core UI engine and managed internationalization.'),
        Work(name: 'Startup Innovations', position: 'Fullstack Dev', startDate: '2018-06-01', endDate: '2020-12-31', summary: 'Developed initial MVP from scratch using modern web technologies.'),
      ],
      skills: [
        Skill(name: 'Mobile Development', keywords: ['Flutter', 'Dart', 'React Native']),
        Skill(name: 'Backend Systems', keywords: ['Node.js', 'Go', 'GCP']),
      ],
      education: [
        Education(institution: 'Institute of Technology', studyType: 'Bachelors', area: 'Software Engineering', score: '3.9/4.0'),
      ],
    );
  }
}

class Basics {
  String name;
  String label;
  String image;
  String email;
  String phone;
  String url;
  String summary;
  /// Optional; used by Priority Resume and similar templates (personal details).
  String dateOfBirth;
  String gender;
  String maritalStatus;
  String category;
  Location location;
  List<Profile> profiles;

  Basics({
    this.name = '',
    this.label = '',
    this.image = '',
    this.email = '',
    this.phone = '',
    this.url = '',
    this.summary = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.maritalStatus = '',
    this.category = '',
    Location? location,
    List<Profile>? profiles,
  })  : location = location ?? Location(),
        profiles = profiles ?? [];

  factory Basics.fromJson(Map<String, dynamic> json) {
    return Basics(
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      profiles: json['profiles'] != null
          ? List<Profile>.from(
              json['profiles'].map((x) => Profile.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'image': image,
      'email': email,
      'phone': phone,
      'url': url,
      'summary': summary,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'category': category,
      'location': location.toJson(),
      'profiles': profiles.map((x) => x.toJson()).toList(),
    };
  }
}

class Location {
  String address;
  String postalCode;
  String city;
  String countryCode;
  String region;

  Location({
    this.address = '',
    this.postalCode = '',
    this.city = '',
    this.countryCode = '',
    this.region = '',
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'postalCode': postalCode,
      'city': city,
      'countryCode': countryCode,
      'region': region,
    };
  }
}

class Profile {
  String network;
  String username;
  String url;

  Profile({
    this.network = '',
    this.username = '',
    this.url = '',
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      network: json['network']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'network': network,
      'username': username,
      'url': url,
    };
  }
}

class Work {
  String name;
  String position;
  String url;
  String startDate;
  String endDate;
  String summary;
  List<String> highlights;

  Work({
    this.name = '',
    this.position = '',
    this.url = '',
    this.startDate = '',
    this.endDate = '',
    this.summary = '',
    List<String>? highlights,
  }) : highlights = highlights ?? [];

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      name: json['name']?.toString() ?? json['company']?.toString() ?? '',
      position: json['position']?.toString() ?? json['role']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position,
      'url': url,
      'startDate': startDate,
      'endDate': endDate,
      'summary': summary,
      'highlights': highlights,
    };
  }
}

class Volunteer {
  String organization;
  String position;
  String url;
  String startDate;
  String endDate;
  String summary;
  List<String> highlights;

  Volunteer({
    this.organization = '',
    this.position = '',
    this.url = '',
    this.startDate = '',
    this.endDate = '',
    this.summary = '',
    List<String>? highlights,
  }) : highlights = highlights ?? [];

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      organization: json['organization']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization': organization,
      'position': position,
      'url': url,
      'startDate': startDate,
      'endDate': endDate,
      'summary': summary,
      'highlights': highlights,
    };
  }
}

class Education {
  String institution;
  String url;
  String area;
  String studyType;
  String startDate;
  String endDate;
  String score;
  List<String> courses;

  Education({
    this.institution = '',
    this.url = '',
    this.area = '',
    this.studyType = '',
    this.startDate = '',
    this.endDate = '',
    this.score = '',
    List<String>? courses,
  }) : courses = courses ?? [];

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution']?.toString() ?? json['college']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      area: json['area']?.toString() ?? json['degree']?.toString() ?? '',
      studyType: json['studyType']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
      courses: json['courses'] != null
          ? List<String>.from(json['courses'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'url': url,
      'area': area,
      'studyType': studyType,
      'startDate': startDate,
      'endDate': endDate,
      'score': score,
      'courses': courses,
    };
  }
}

class Award {
  String title;
  String date;
  String awarder;
  String summary;

  Award({
    this.title = '',
    this.date = '',
    this.awarder = '',
    this.summary = '',
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      awarder: json['awarder']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'awarder': awarder,
      'summary': summary,
    };
  }
}

class Publication {
  String name;
  String publisher;
  String releaseDate;
  String url;
  String summary;
  /// Shown on Priority resume as "Skills used - …" (optional).
  String skillsUsed;

  Publication({
    this.name = '',
    this.publisher = '',
    this.releaseDate = '',
    this.url = '',
    this.summary = '',
    this.skillsUsed = '',
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      name: json['name']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      summary: json['summary']?.toString() ?? json['description']?.toString() ?? '',
      skillsUsed: json['skillsUsed']?.toString() ??
          json['skills_used']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'publisher': publisher,
      'releaseDate': releaseDate,
      'url': url,
      'summary': summary,
      'skillsUsed': skillsUsed,
    };
  }
}

class Skill {
  String name;
  String level;
  List<String> keywords;

  Skill({
    this.name = '',
    this.level = '',
    List<String>? keywords,
  }) : keywords = keywords ?? [];

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'keywords': keywords,
    };
  }
}

class Language {
  String language;
  String fluency;

  Language({
    this.language = '',
    this.fluency = '',
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      language: json['language']?.toString() ?? '',
      fluency: json['fluency']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'fluency': fluency,
    };
  }
}

class Interest {
  String name;
  List<String> keywords;

  Interest({
    this.name = '',
    List<String>? keywords,
  }) : keywords = keywords ?? [];

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      name: json['name']?.toString() ?? '',
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'keywords': keywords,
    };
  }
}

class Reference {
  String name;
  String reference;

  Reference({
    this.name = '',
    this.reference = '',
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      name: json['name']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reference': reference,
    };
  }
}
