class HelpSupportDto {
  final ContactInfo contact;
  final List<FaqDto> faqs;

  HelpSupportDto({
    required this.contact,
    required this.faqs,
  });

  factory HelpSupportDto.fromJson(Map<String, dynamic> json) => HelpSupportDto(
        contact: ContactInfo.fromJson(json['contact']),
        faqs: (json['faqs'] as List?)
                ?.map((e) => FaqDto.fromJson(e))
                .toList() ??
            [],
      );
}

class ContactInfo {
  final String email;
  final List<String> phones;
  final String website;

  ContactInfo({
    required this.email,
    required this.phones,
    required this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        email: json['email'] ?? '',
        phones: (json['phones'] as List?)?.map((e) => e.toString()).toList() ?? [],
        website: json['website'] ?? '',
      );
}

class FaqDto {
  final int id;
  final String question;
  final String answer;
  final int order;

  FaqDto({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory FaqDto.fromJson(Map<String, dynamic> json) => FaqDto(
        id: json['id'] ?? 0,
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        order: json['order'] ?? 0,
      );
}

