require 'spec_helper'

# use Admin::BooksController / Admin::AuthorsController as it inherit Releaf::BaseController and
# have no extra methods or overrides
describe Admin::AuthorsController do
  before do
    sign_in FactoryGirl.create(:user)
  end

  describe "GET #new_attachment" do
    it "renders 'new_attachment' view" do
      get :new_attachment
      expect( response ).to be_successful
      expect( response ).to render_template('new_attachment')
    end
  end

  describe "#create_attachment" do
    let(:image) { Rack::Test::UploadedFile.new(File.expand_path('../fixtures/cs.png', __dir__), "image/png") }
    let(:file) { Rack::Test::UploadedFile.new(File.expand_path('../fixtures/time.formats.xlsx', __dir__), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") }

    context "when image is uploaded" do
      it "renders '_attachment_image'" do
        post :create_attachment, :file => image
        expect( response ).to be_successful
        expect( response ).to render_template('_attachment_image')
      end

      it "creates attachment" do
        expect do
          post :create_attachment, :file => image
        end.to change { Releaf::Attachment.count }.by(1)
      end
    end

    context "when file is uploaded" do
      it "renders '_attachment_link'" do
        post :create_attachment, :file => file
        expect( response ).to be_successful
        expect( response ).to render_template('_attachment_link')
      end

      it "creates attachment" do
        expect do
          post :create_attachment, :file => file
        end.to change { Releaf::Attachment.count }.by(1)
      end
    end

    context "when no file is uploaded" do
      it "responds with success" do
        post :create_attachment
        expect( response ).to be_successful
      end

      it "doesn't create attachment" do
        expect do
          post :create_attachment
        end.to_not change { Releaf::Attachment.count }
      end
    end

  end

  describe "#index_url" do
    context "when action is other than :index" do
      context "when params have 'index_url' defined" do
        it "returns params 'index_url'" do
          url = "/admin/something?a=1&b=2"
          get :new, index_url: url
          expect(subject.index_url).to eq(url)
        end
      end

      context "when does not have 'index_url' defined" do
        it "returns index action url" do
          get :new
          expect(subject.index_url).to eq("http://test.host/admin/authors")
        end
      end
    end

    context "when action is :index" do
      it "returns #current_url value" do
        get :index
        allow(subject).to receive(:current_url).and_return("random_string")
        expect(subject.index_url).to eq("random_string")
      end
    end
  end

  describe "#current_url" do
    it "returns current url without internal params" do
      get :index, ajax: 1, search: "something", page: 1
      expect(subject.current_url).to eq("/admin/authors?page=1&search=something")
    end
  end

  describe "GET index" do
    before do
      21.times do |i|
        FactoryGirl.create(:author)
      end
    end

    context "when @resources_per_page is nil" do
      it "assigns all resources to @collection" do
        get :index, show_all: 1
        expect(assigns(:collection).is_a?(ActiveRecord::Relation)).to be true
        expect(assigns(:collection).size).to eq(21)
      end
    end

    context "when @resources_per_page is not nil" do
      it "assigns maximum 20 resources to @collection" do
        get :index
        expect(assigns(:collection).is_a?(ActiveRecord::Relation)).to be true
        expect(assigns(:collection).size).to eq(20)
      end
    end
  end


  describe "DELETE #destroy" do
    before do
       @author = FactoryGirl.create(:author)
       FactoryGirl.create(:book, title: "The book", author: @author)
       FactoryGirl.create(:book, title: "Almost the book", author: @author)
    end

    it "creates flash error with message" do
      delete :destroy, id: @author
      expect(flash[:error]).to eq({id: :resource_status, message: "Cant destroy, because relations exists"})
    end
  end
end


describe Admin::BooksController do
  before do
    sign_in FactoryGirl.create(:user)
    @breadcrumbs_base = [
      {name: I18n.t('home', scope: 'admin.breadcrumbs'), url: releaf_root_path},
      {name: I18n.t('admin/books', scope: "admin.menu_items"), url: admin_books_path},
    ]
  end

  describe "GET #index" do
    before do
      FactoryGirl.create(:book, title: "great one")
      FactoryGirl.create(:book, title: "bad one")
      FactoryGirl.create(:book, title: "average third")
    end

    context "when empty search string given" do
      it "shows all records" do
        get :index, search: ""
        expect(assigns(:collection).count).to eq(3)
      end
    end

    context "when search string with multiple words given" do
      it "searches by given string" do
        get :index, search: "one grea"
        expect(assigns(:collection).count).to eq(1)
      end
    end

    context "when search string given" do
      it "searches by given string" do
        get :index, search: "great"
        expect(assigns(:collection).count).to eq(1)
      end
    end

    context "when no search given" do
      it "shows all records" do
        get :index
        expect(assigns(:collection).count).to eq(3)
      end
    end
  end

  describe "GET #new" do
    it "assigns the requested record to @resource" do
      get :new

      expect(assigns(:resource).new_record?).to be true
    end

    context "when the requested record responds to #to_text" do
      it "uses the result of #to_text for resource's breadcrumb name" do
        get :new
        breadcrumbs = @breadcrumbs_base + [{name: "New record", url: new_admin_book_path}]

        expect(assigns(:breadcrumbs)).to eq(breadcrumbs)
      end
    end
  end

  describe "GET #edit" do
    before do
      @resource = FactoryGirl.create(:book)
    end

    it "assigns the requested record to @resource" do
      get :edit, id: @resource

      expect(assigns(:resource)).to eq(@resource)
    end

    context "when the requested record responds to #to_text" do
      it "uses the result of #to_text for resource's breadcrumb name" do
        get :edit, id: @resource
        breadcrumbs = @breadcrumbs_base + [{name: @resource.to_text, url: edit_admin_book_path(@resource.id)}]

        expect(assigns(:breadcrumbs)).to eq(breadcrumbs)
      end
    end

    context "when the requested record does not respond to #to_text" do
      it "uses default translation for resource's breadcrumb name" do
        skip "Find out way how to stub loaded resource #respond_to?(:to_text)"
        allow_any_instance_of(Book).to receive(:respond_to?).with(:to_text).and_return(false)
        get :edit, id: @resource
        breadcrumbs = @breadcrumbs_base + [{name: "Edit resource", url: edit_admin_book_path(@resource.id)}]

        expect(assigns(:breadcrumbs)).to eq(breadcrumbs)
      end
    end
  end
end
