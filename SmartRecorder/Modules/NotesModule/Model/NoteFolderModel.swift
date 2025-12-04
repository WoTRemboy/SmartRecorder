//
//  NoteFolderModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//

enum NoteFolder: String, CaseIterable {
    case all = "All"
    case work = "Work"
    case study = "Study"
    case personal = "Personal"
    
    static internal var selectCases: [NoteFolder] {
        [.work, .study, .personal]
    }
    
    internal var title: String {
        switch self {
        case .all:
            return Texts.NoteFolder.all
        case .work:
            return Texts.NoteFolder.work
        case .study:
            return Texts.NoteFolder.study
        case .personal:
            return Texts.NoteFolder.personal
        }
    }
}
