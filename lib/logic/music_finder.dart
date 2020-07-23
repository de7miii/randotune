import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

class MusicFinder with ChangeNotifier {
  final FlutterAudioQuery aq = FlutterAudioQuery();

  List<SongInfo> _allSongs = [];
  List<AlbumInfo> _allAlbums = [];
  List<ArtistInfo> _allArtists = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  SongInfo _playing;
  AudioPlayer _audioPlayer = AudioPlayer();
  double _currentSongDuration = 0.0;
  double _currentSongPosition = 0.0;
  SongInfo _upNext;
  AlbumInfo _selectedAlbum;
  List<SongInfo> _selectedAlbumSongs = [];

  List<SongInfo> get allSongs => _allSongs;
  List<AlbumInfo> get allAlbums => _allAlbums;
  List<ArtistInfo> get allArtists => _allArtists;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  SongInfo get currentlyPlaying => _playing;
  AudioPlayer get audioPlayer => _audioPlayer;
  double get currentSongDuration => _currentSongDuration;
  double get currentSongPosition => _currentSongPosition;
  SongInfo get upNext => _upNext;
  AlbumInfo get selectedAlbum => _selectedAlbum;
  List<SongInfo> get selectedAlbumSongs => _selectedAlbumSongs;

  set isPlaying(bool newVal) {
    assert(newVal != null);
    _isPlaying = newVal;
    notifyListeners();
  }

  set currentlyPlaying(SongInfo newSong) {
    assert(newSong != null);
    _playing = newSong;
    currentSongDuration = double.parse(newSong.duration);
    isPlaying = true;
    notifyListeners();
  }

  set upNext(SongInfo newSong) {
    assert(newSong != null);
    _upNext = newSong;
    notifyListeners();
  }

  set currentSongPosition(double newPos) {
    assert(newPos != null);
    _currentSongPosition = newPos;
    notifyListeners();
  }

  set currentSongDuration(double newDur) {
    assert(newDur != null);
    _currentSongDuration = newDur;
    notifyListeners();
  }

  set selectedAlbum(AlbumInfo newAlbum) {
    assert(newAlbum != null);
    _selectedAlbum = newAlbum;
    notifyListeners();
  }

  set selectedAlbumSongs(List<SongInfo> albumSongs) {
    assert(albumSongs != null);
    _selectedAlbumSongs = albumSongs;
    notifyListeners();
  }

  findAllSongs({SongSortType sortType = SongSortType.DISPLAY_NAME}) {
    _isLoading = true;
    aq.getSongs(sortType: sortType).then((songsList) {
      _allSongs = songsList;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      print(err);
    });
  }

  findAllAlbums({AlbumSortType sortType = AlbumSortType.DEFAULT}) {
    _isLoading = true;
    aq.getAlbums(sortType: sortType).then((albumList) {
      _allAlbums = albumList;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      print(err);
    });
  }

  findAlbumSongs({@required String albumId}) {
    _isLoading = true;
    aq.getSongsFromAlbum(albumId: albumId, sortType: SongSortType.SMALLER_TRACK_NUMBER).then(
      (songsList) {
        print(songsList);
        _selectedAlbumSongs = songsList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) => print(err),
    );
  }

  findAllArtists({ArtistSortType sortType = ArtistSortType.DEFAULT}) {
    aq.getArtists(sortType: sortType).then((artistsList) {
      _allArtists = artistsList;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      print(err);
    });
  }

  playSong(SongInfo song) async {
    assert(song != null);
    assert(audioPlayer != null);
    audioPlayer.setReleaseMode(ReleaseMode.STOP);
    int res = await audioPlayer.play(song.filePath, isLocal: true);
    if (res == 1) {
      getPlayingSongPosition();
      print("Playing: ${song.title}");
      notifyListeners();
    }
    audioPlayer.onPlayerCompletion.listen((event) {
      print('song finished');
      Future.delayed(Duration(seconds: 5));
      currentSongPosition = 0.0;
      currentlyPlaying = upNext;
      notifyListeners();
      playSong(currentlyPlaying);
    });
  }

  pauseSong() async {
    assert(audioPlayer != null);
    await audioPlayer.pause();
  }

  resumeSong() async {
    assert(audioPlayer != null);
    await audioPlayer.resume();
  }

  seek({@required int duration}) async {
    assert(audioPlayer != null);
    assert(duration != null);
    if (audioPlayer.state == AudioPlayerState.PLAYING ||
        audioPlayer.state == AudioPlayerState.PAUSED) {
      if (duration == 0) {
        await audioPlayer.seek(Duration(seconds: 0));
        currentSongPosition = 0.0;
        notifyListeners();
      } else {
        await audioPlayer.seek(Duration(seconds: duration));
        notifyListeners();
      }
    }
  }

  getPlayingSongPosition() async {
    assert(audioPlayer != null);
    if (audioPlayer.state == AudioPlayerState.PLAYING) {
      audioPlayer.onAudioPositionChanged.listen((event) {
        currentSongPosition = event.inMilliseconds.toDouble();
        notifyListeners();
        if ((currentSongDuration - event.inMilliseconds < 10000 &&
                upNext == null) ||
            (upNext == currentlyPlaying &&
                currentSongDuration - event.inMilliseconds < 10000)) {
          upNext = allSongs[Random.secure().nextInt(allSongs.length)];
          print("Up next: ${upNext.title}");
        }
      });
    }
  }
}
