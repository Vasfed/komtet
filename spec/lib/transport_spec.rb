# frozen_string_literal: true

RSpec.describe Komtet::Transport do

  let(:credentials){
    Komtet::Credentials.new(
      shop_id:'some_shop123', signature_key:'key1234'
    )
  }
  subject{
    described_class.new('https://kassa.komtet.ru/api/shop/v1/', credentials)
  }

  describe "signs requests" do
    it "via get" do
      req = stub_request(:get, "https://kassa.komtet.ru/api/shop/v1/queues/125").
        with(
         headers: {
          'Accept'=>'application/json',
          'Authorization' => 'some_shop123',
          'X-Hmac-Signature'=>'cc30e8e8b031d6edc15d88268ee80052', # secret = 'key1234'
         }).to_return(status: 200, body: "{}", headers: {'Content-Type' => "application/json; charset=UTF-8"})

      res = subject.transport.get('queues/125')
      expect(req).to have_been_requested
      expect(res.body).to be_a(Hash)
    end

    it "via post" do
      req = stub_request(:post, "https://kassa.komtet.ru/api/shop/v1/queues/125/task").
        with(
         headers: {
          'Accept'=>'application/json',
          'Authorization' => 'some_shop123',
          'X-Hmac-Signature'=>'7e740fe94306fcabc244df0c09386709', # secret = 'key1234'
         }).to_return(status: 200, body: "{}", headers: {'Content-Type' => "application/json; charset=UTF-8"})

      res = subject.transport.post('queues/125/task', foo: :bar)
      expect(req).to have_been_requested
      expect(res.body).to be_a(Hash)
    end
  end

  describe "post_task" do
    let(:response){
      { id: 1, external_id: "1234BAR", print_queue_id: 123, state: "new"}
    }

    let!(:request){
      stub_request(:post, "https://kassa.komtet.ru/api/shop/v1/queues/123/task").
        to_return(status: 200, body: response.to_json, headers: {'Content-Type' => "application/json; charset=UTF-8"})
    }

    it "works" do
      subject.post_task({some: :info}, 123)
    end
  end

  describe "get task" do
    let(:response){
      { id: 1, external_id: "1234BAR", print_queue_id: 123, state: "new"}
    }

    let!(:request){
      stub_request(:get, "https://kassa.komtet.ru/api/shop/v1/tasks/321").
        to_return(status: 200, body: response.to_json, headers: {'Content-Type' => "application/json; charset=UTF-8"})
    }
    it "works" do
      subject.task_result(321)
    end
  end

  describe "get queue status" do
    let(:response){ { id: 6395, state: "active" } }
    let(:status){ 200 }
    let!(:request){
      stub_request(:get, "https://kassa.komtet.ru/api/shop/v1/queues/6395").
        to_return(status: status, body: response.to_json, headers: {'Content-Type' => "application/json; charset=UTF-8"})      
    }

    it "works" do
      expect(subject.queue_status(6395)).to eq 'active'
    end

    context "when access denied" do
      let(:response){ { title:"Ошибка авторизации", description:"Проверьте правильность написания идентификатора магазина и его секрета", code:"AUT00" } }
      let(:status){ 403 }
      it "works" do
        expect(subject.queue_status(6395)).to eq 'access_denied'
      end
    end
  end

end