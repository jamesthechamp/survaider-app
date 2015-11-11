function RankingQuestion(label, required, cid, field_type, next){
  Question.call(this, label, required, cid, field_type, next);
  this.subparts = [];
}

function RankingSubpart(label, rank){
  this.label = label;
  this.rank = rank;
}

RankingQuestion.prototype = Object.create(Question.prototype);
RankingQuestion.prototype.constructor = RankingQuestion;

RankingQuestion.prototype.insertSubpart = function(label, rank){
  this.subparts.push(new RankingSubpart(label, rank));
};

RankingQuestion.prototype.change = function(index, rank){
  console.log(this);
  var isCompleted = this.checkIfCompleted();
  if (isCompleted) {
    this.completed();
    console.log("The question is completed");
  }
  else{
    this.inComplete();
  }
};

RankingQuestion.prototype.checkIfCompleted = function(){

  this.completed();
  return true;

}

RankingQuestion.prototype.resetResponse = function(){

  for (var i = 0; i < this.subparts.length; i++) {
    this.subparts[i].rank = -1;
  }

}


RankingQuestion.prototype.generateResponse = function(){
  var response = {
    id: this.id,
    type: this.type,
    response: []
  }


  var temp = [],
      delimeter1 = '##';
      delimeter2 = '###';

  for (var i = 0; i < this.subparts.length; i++) {
    temp.push('a_' + (i + 1) + delimeter1 + (this.subparts[i].rank+1));
  }


  response.response = temp.join(delimeter2).toLocaleString();

  return response;
}
