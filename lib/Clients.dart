import 'dart:convert';

import 'package:http/http.dart' as http;

import 'Candidate.dart';
import 'ElectionLocation.dart';
import 'Elector.dart';

//todo you should have the same naming as you have in backend. e.g. if you have UserController, here you should have UserClient
class Clients{

  // remove all static keywords from everwhere in this class
  // each method should make an http call and return e.g candidates, so there is no need to keep them here
  static List<Elector> electors = [];
  static List<ElectionLocation> electionLocations = [];
  static List<Candidate> candidates = [];
  static var statistics = {};

  
  static String electorsUrl = "http://localhost:8080/electors";
  static String electionLocationsUrl = "http://localhost:8080/electionLocation";
  static String candidatesUrl = "http://localhost:8080/candidates";
  static String statisticsUrl = "http://localhost:8080/statistics";
  static String votesUrl = "http://localhost:8080/votes";

  static dynamic addCandidate(String firstName, String lastName, String number) async {
    await http.post(
      Uri.parse(candidatesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(
          {'firstName': firstName, 'lastName': lastName, 'number': number}),
    );
  }

  static dynamic findElectorByPassportNumber(String passportNumber) async {
    final electorResponse =
    await http.get(Uri.parse('$electorsUrl/$passportNumber'));
    final electorData = jsonDecode(electorResponse.body);
    int electorId = electorData['id'];
    return electorId;
  }

  static dynamic vote(String passportNumber, String electionLocationId, String candidateId) async {
    int electorId = await findElectorByPassportNumber(passportNumber);

    await http.post(
      Uri.parse(votesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'electorId': electorId,
        'electionLocationId': int.parse(electionLocationId),
        'candidateId': int.parse(candidateId)
      }),
    );
  }

  static dynamic addElector(String firstName, String lastName, String passportNumber, String dateOfBirth) async {
    DateTime date = DateTime.parse(dateOfBirth);
    String dateTime = date.toIso8601String();

    await http.post(
      Uri.parse(electorsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'passportNumber': passportNumber,
        'dateOfBirth': dateTime,
      }),
    );
  }

  static dynamic addElectionLocation(String address) async {
    await http.post(
      Uri.parse(electionLocationsUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({'address': address}),
    );
  }

  //todo the method should return list of Candidaes.
  //todo create response dto classes, as you have in backend, and write json parsing login there as factory methods.
  //e.g GetAllElectoresResponseDto.fromJson(...)
  static getAll() async {
    final electorsResponse = await http.get(Uri.parse(electorsUrl));
    final electionLocationsResponse =
    await http.get(Uri.parse(electionLocationsUrl));
    final candidatesResponse = await http.get(Uri.parse(candidatesUrl));

      electors = List<Elector>.from(
        json
            .decode(electorsResponse.body)
            .map((data) => Elector.fromJson(data)),
      );
      electionLocations = List<ElectionLocation>.from(
        json
            .decode(electionLocationsResponse.body)
            .map((data) => ElectionLocation.fromJson(data)),
      );
      candidates = List<Candidate>.from(
        json
            .decode(candidatesResponse.body)
            .map((data) => Candidate.fromJson(data)),
      );
  }

  static getStatistics() async {
    final statisticsResponse = await http.get(Uri.parse(statisticsUrl));
      var data = jsonDecode(statisticsResponse.body);

      Map<String, dynamic> statisticsData = data['statistics'];

      Map<int, Map<int, double>> statisticsMap = {};

      statisticsData.forEach((k1, k2) {
        Map<int, double> candidateStatistics = {};
        (k2 as Map<String, dynamic>).forEach((innerKey, value) {
          candidateStatistics[int.parse(innerKey)] = (value as num).toDouble();
        });
        statisticsMap[int.parse(k1)] = candidateStatistics;
      });

      statistics = statisticsMap;
  }
}
