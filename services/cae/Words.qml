import QtQuick
import Caelestia.Services

// The shell's lyrics fetcher. Forge reads the *results* off disk either way;
// this is only the part that asks caelestia to go and fetch them, which is
// why without it the cache simply never fills.
Item {
    function setTrack(artist: string, title: string, album: string, length: real): void {
        Lyrics.setTrack(artist, title, album, length);
    }

    function clearTrack(): void {
        Lyrics.clearTrack();
    }
}
