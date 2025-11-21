//
//  NoteFolderModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 13/11/2025.
//

enum NoteFolder: String, CaseIterable {
    case all = "note_folder_all"
    case work = "note_folder_work"
    case study = "note_folder_study"
    case personal = "note_folder_personal"
    
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
