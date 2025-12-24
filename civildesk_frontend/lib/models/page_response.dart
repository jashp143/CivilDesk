/// Generic paginated response model matching Spring Data Page structure
/// Used for all paginated API responses
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Spring Data Page with VIA_DTO mode wraps pagination metadata in a 'page' object
    final pageData = json['page'] as Map<String, dynamic>?;
    
    // Extract pagination data from page object if available, otherwise from top level
    final paginationData = pageData ?? json;
    
    // Calculate first and last if not provided
    final number = paginationData['number'] as int? ?? 0;
    final totalPages = paginationData['totalPages'] as int? ?? 0;
    final first = paginationData['first'] as bool? ?? (number == 0);
    final last = paginationData['last'] as bool? ?? (totalPages > 0 && number >= totalPages - 1);
    
    return PageResponse<T>(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: paginationData['totalElements'] as int? ?? 0,
      totalPages: totalPages,
      size: paginationData['size'] as int? ?? 10,
      number: number,
      first: first,
      last: last,
    );
  }

  bool get hasMore => !last;
  bool get isEmpty => content.isEmpty;
}

