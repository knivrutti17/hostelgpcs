class StudentModel {
  final String uid;
  final String name;
  final String branch; // IT, Civil, Mechanical
  final String category; // Open, SC, ST, OBC
  final String hostel; // Devgiri or Shivneri
  final String roomNo;
  final String status; // Pending, Approved, Rejected

  StudentModel({
    required this.uid, required this.name, required this.branch,
    required this.category, required this.hostel, required this.roomNo,
    this.status = "Pending",
  });

  // Convert Firebase document to Student Object
  factory StudentModel.fromMap(Map<String, dynamic> data, String id) {
    return StudentModel(
      uid: id,
      name: data['name'] ?? '',
      branch: data['branch'] ?? '',
      category: data['category'] ?? '',
      hostel: data['hostelName'] ?? '',
      roomNo: data['roomNo'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
    );
  }
}