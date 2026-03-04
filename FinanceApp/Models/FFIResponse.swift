import Foundation

// MARK: - Generic FFI Response

/// Wraps the JSON response returned by all FFI functions.
/// Format: {"success": bool, "code": int, "message": string, "data": T?}
struct FFIResponse<T: Decodable>: Decodable {
    let success: Bool
    let code: Int
    let message: String
    let data: T?
}

/// Used for FFI calls that return no data payload.
struct EmptyData: Decodable {}

// MARK: - Paginated Response

/// Generic wrapper for FFI endpoints that return paginated results.
/// Format: {"items": [T], "total_count": Int, "has_more": Bool}
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let totalCount: Int
    let hasMore: Bool
}
