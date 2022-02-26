import SwiftUI

struct LandingPageView: View {
    @StateObject var viewModel = ViewModel()
    @State var uploadImage = false
    @State var isUpload = false
    @StateObject var persons = People()
    @StateObject var itemsTemp = Items()
    // @ObservedObject var itemsTemp = Items()
    @State var temp = [Item]()
    
    var body: some View {
        
        NavigationView{
            VStack(spacing: 32) {
                Spacer()
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    NavigationLink(destination: Names(), isActive: $isUpload) {
                        VStack{
                            Button(action: {
                                viewModel.sendBase64(image: image, completion: {list in
                                    DispatchQueue.main.async {
                                        self.itemsTemp.itemsList = list!
                                        print ("notified", self.itemsTemp.itemsList)
                                        self.isUpload = true
                                    }
                                })
                            }) {
                                Text("Upload Photo")
                                    .font(.headline)
                            }
                        }
                    }
                }
                else {
                    Text("Upload an image of a receipt")
                }
                Spacer()
                VStack(spacing: 32) {
                    
                    Button(action: viewModel.choosePhoto, label: {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                        Text("Choose Photo")
                            .font(.headline)
                    })
                    Button(action: viewModel.takePhoto, label: {
                        Image(systemName: "camera")
                            .font(.system(size: 20))
                        Text("Take a Photo")
                            .font(.headline)
                    })
                }.padding()
                
                
            }
            .navigationTitle("TabDrop")
            .fullScreenCover(isPresented: $viewModel.isPresentingImagePicker, content: {
                ImagePicker(sourceType: viewModel.sourceType, completionHandler: viewModel.didSelectImage)
            })
        }
        .navigationViewStyle(.stack)
        .environmentObject(persons)
        .environmentObject(itemsTemp)
    }
}

struct ContentView: View {

    var body: some View {
        LandingPageView()
    }
}

// https://augmentedcode.io/2020/11/22/using-an-image-picker-in-swiftui/
class ViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isPresentingImagePicker = false
    @ObservedObject var itemsTemp = Items()
    var itemsArr = [Item]()
    private(set) var sourceType: ImagePicker.SourceType = .camera
    
    func choosePhoto() {
        sourceType = .photoLibrary
        isPresentingImagePicker = true
    }
    
    func takePhoto() {
        sourceType = .camera
        isPresentingImagePicker = true
    }
    
    func didSelectImage (image: UIImage?) {
        selectedImage = image
        isPresentingImagePicker = false
    }
    
    func convertImageToBase64String (img: UIImage) -> String {
        let imageData:NSData = img.pngData()! as NSData
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        return strBase64
    }
    
    func sendBase64 (image: UIImage, completion: @escaping ([Item]?) -> Void) {
        let strBase64 = convertImageToBase64String(img: image)
        let Url = String(format: "http://127.0.0.1:5000/get_items")
        guard let serviceUrl = URL(string: Url) else {
            completion(nil)
            return
        }
        let parameterDictionary = ["base64" : strBase64]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            completion(nil)
            return
        }
        request.httpBody = httpBody

        let session = URLSession.shared
        session.dataTask(with: request) { (data, _, error) in
//            if let response = response {
//                //print(response)
//            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let object = json as? [Any] {
                        self.itemsArr = []
                        for anItem in object as! [Dictionary<String, AnyObject>] {
                            let item = anItem["item_name"] as! String
                            let price = anItem["price"] as! Double
                            let full_item = Item(name: item, price: price, pplList: [String]())
                            self.itemsArr.append(full_item)
                        }
                        // print ("dispatch", self.itemsArr)
                        completion(self.itemsArr)
                    } else { completion(nil) }
                } catch {
                    print("error", error)
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

