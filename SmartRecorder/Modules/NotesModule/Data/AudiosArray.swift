//
//  AudiosArray.swift
//  SmartDictophone
//
//  Created by Георгий Асеев on 30.10.2025.
//

import Foundation

var allAudios: [Note] = [Note(headline: "Headline с учёбой",
                                       subheadline: "Сегодня обсудим что-то важное, Сегодня обсудим что-то важное, Сегодня обсудим что-то важное, Сегодня обсудим что-то важное, Сегодня обсудим что-то важное",
                                       date: "Apr 1, 2025",
                                       time: "9:41 AM",
                                       duration: "16:12:00",
                              category: NoteFolder.study.rawValue,
                                       location: "Санкт-Петербург"),
                                      Note(headline: "Headline с работой",
                                       subheadline: "Сегодня обсудим что-то важное",
                                       date: "Apr 1, 2025",
                                       time: "9:41 AM",
                                       duration: "16:12:00",
                                       category: NoteFolder.work.rawValue,
                                       location: "Санкт-Петербург"),
                                      Note(headline: "Headline с личным",
                                       subheadline: "Сегодня обсудим что-то важное",
                                       date: "Apr 1, 2025",
                                       time: "9:41 AM",
                                       duration: "16:12:00",
                                       category: NoteFolder.personal.rawValue,
                                       location: "Санкт-Петербург")]
