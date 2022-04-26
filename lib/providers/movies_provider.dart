import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peliculas/helpers/debouncer.dart';
import 'package:peliculas/models/models.dart';
import 'package:peliculas/models/search_movie_response.dart';



class MoviesProvider  extends ChangeNotifier {

  String _apiKey   = 'dc90b3d07c9a5399b89a4aeb025cc31e';
  String _baseUrl  = 'api.themoviedb.org';
  String _language = 'es-ES';

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];
  
  Map<int, List<Cast>> movieCast = {}; 

  int _popularPage = 0;
  final debouncer = Debouncer(
    duration: Duration(milliseconds: 500)
    );
  final StreamController<List<Movie>> _suggestionStreamController = new StreamController.broadcast(); 
  Stream<List<Movie>> get suggestionStream => _suggestionStreamController.stream;
  
  MoviesProvider() {
    print('Movies provider inicializado');
    this.getOnDisplayMovies();
    this.getPopularMovies();
  }

  // Este metodo se hizo para optimizar el codigo ya que se repitia la forma en que se hace la peticion
  Future<String> _getJsonData(String endpoint, [int page = 1]) async {
     final url = Uri.https(_baseUrl, endpoint, {
      'api_key' : _apiKey,
      'language' : _language,
      'page' : '$page'
      });

    final response = await http.get(url);

    return response.body;
  }


  getOnDisplayMovies() async {

    // var url = Uri.https(_baseUrl, '/3/movie/now_playing', {
    //   'api_key' : _apiKey,
    //   'language' : _language,
    //   'page' : '1'
    //   });

    // final response = await http.get(url);
    // final nowPlayingResponse = NowPlayingResponse.fromJson(response.body);
    
    final jsonData = await this._getJsonData('/3/movie/now_playing');
    final nowPlayingResponse = NowPlayingResponse.fromJson(jsonData);
    
    onDisplayMovies = nowPlayingResponse.results;
    notifyListeners();
  }

  getPopularMovies() async {
    // var url = Uri.https(_baseUrl, '/3/movie/popular', {
    //   'api_key' : _apiKey,
    //   'language' : _language,
    //   'page' : '1'
    //   });

    // final response = await http.get(url);
    // final popularResponse = PopularResponse.fromJson(response.body);
    _popularPage++;
    final jsonData = await this._getJsonData('/3/movie/popular', _popularPage);
    final popularResponse = PopularResponse.fromJson(jsonData);
    popularMovies = [...popularMovies, ...popularResponse.results ];
    notifyListeners();
  }

  Future<List<Cast>> getMovieCast(int movieId) async {
    // TODO Revisar el mapa   

    if(movieCast.containsKey(movieId)) return movieCast[movieId]; 

    final jsonData = await this._getJsonData('/3/movie/${movieId}/credits');
    final creditsResponse = CreditsResponse.fromJson(jsonData);
    movieCast[movieId] = creditsResponse.cast;

    return creditsResponse.cast;
  }


  Future<List<Movie>> searchMovies(String  query) async {
    final url = Uri.https(_baseUrl, '3/search/movie', {
      'api_key' : _apiKey,
      'language' : _language,
      'query': query
      });

    final response = await http.get(url);
    final searchResponse = SearchResponse.fromJson(response.body);
    return searchResponse.results;
  }

  void getSuggestionsByQuery(String searchTerm){
    debouncer.value = '';
    debouncer.onValue = (value)  async {
      // print('tenemos valor a buscar:$value');
      final results = await this.searchMovies(value);
      this._suggestionStreamController.add(results);
    };

    final timer = Timer.periodic(Duration(milliseconds: 300), ( _ ) { 
        debouncer.value = searchTerm;
    });

    Future.delayed(Duration(milliseconds: 301)).then(( _ ) => timer.cancel());
  }

}