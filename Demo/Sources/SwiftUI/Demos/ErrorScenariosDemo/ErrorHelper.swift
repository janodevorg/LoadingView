import Foundation
import SwiftUI

struct ErrorHelper {
    static func errorIcon(for error: Error) -> String {
        if let demoError = error as? DemoError {
            switch demoError {
            case .networkError: return "wifi.slash"
            case .timeout: return "clock.badge.exclamationmark"
            case .validationError: return "exclamationmark.triangle"
            default: return "exclamationmark.circle"
            }
        } else if let nsError = error as NSError? {
            switch nsError.code {
            case 404: return "doc.badge.gearshape"
            case 401: return "lock.fill"
            case 500: return "server.rack"
            default: return "exclamationmark.octagon"
            }
        }
        return "exclamationmark.circle"
    }

    static func errorColor(for error: Error) -> Color {
        if let demoError = error as? DemoError {
            switch demoError {
            case .networkError: return .orange
            case .timeout: return .purple
            case .validationError: return .red
            default: return .red
            }
        } else if let nsError = error as NSError? {
            switch nsError.code {
            case 404: return .gray
            case 401: return .yellow
            case 500: return .red
            default: return .red
            }
        }
        return .red
    }

    static func errorTitle(for error: Error) -> String {
        if let demoError = error as? DemoError {
            switch demoError {
            case .networkError: return "Connection Failed"
            case .timeout: return "Request Timed Out"
            case .validationError: return "Invalid Data"
            default: return "Error Occurred"
            }
        } else if let nsError = error as NSError? {
            switch nsError.code {
            case 404: return "Not Found"
            case 401: return "Authentication Required"
            case 500: return "Server Error"
            default: return "Error \(nsError.code)"
            }
        }
        return "Unknown Error"
    }

    static func recoverySuggestions(for error: Error) -> [String] {
        if let demoError = error as? DemoError {
            switch demoError {
            case .networkError:
                return [
                    "Check your internet connection",
                    "Try disabling VPN if active",
                    "Restart your router"
                ]
            case .timeout:
                return [
                    "The server might be busy, try again later",
                    "Check if you're on a slow connection",
                    "Consider increasing timeout duration"
                ]
            case .validationError:
                return [
                    "Verify the input data format",
                    "Check for required fields",
                    "Ensure data meets validation rules"
                ]
            default:
                return ["Try again later"]
            }
        } else if let nsError = error as NSError? {
            switch nsError.code {
            case 404:
                return [
                    "Verify the URL is correct",
                    "The resource may have been moved or deleted",
                    "Contact support if this persists"
                ]
            case 401:
                return [
                    "Sign in to your account",
                    "Check if your session has expired",
                    "Verify your credentials"
                ]
            case 500:
                return [
                    "This is a server-side issue",
                    "Try again in a few minutes",
                    "Contact support if the problem persists"
                ]
            default:
                return ["Try again later"]
            }
        }
        return ["Try again later"]
    }
}